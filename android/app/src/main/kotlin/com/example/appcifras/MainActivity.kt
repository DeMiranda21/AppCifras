package com.example.appcifras

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "appcifras/pasta_curada"
        private const val REQUEST_OPEN_DOCUMENT_TREE = 4103
        private const val LOG_TAG = "AppCifrasSAF"
        private const val DOCUMENTS_UI_NOTIFICATION_URI =
            "com.android.documentsui.extra.NOTIFICATION_URI"
    }

    private var pendingSelection: MethodChannel.Result? = null
    private val safExecutor = Executors.newSingleThreadExecutor()
    private val enumerationCoordinator = SafEnumerationCoordinator()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "selecionarPasta" -> selectFolder(result)
            "verificarAcesso" -> withSafErrors(result) {
                val treeUri = requiredUri(call, "uri")
                requirePersistedReadPermission(treeUri)
                queryTreeName(treeUri)
                null
            }
            "listarFilhosDiretos" -> listDirectChildrenAsync(call, result)
            "lerBytes" -> withSafErrors(result) {
                val documentUri = requiredUri(call, "localizador")
                contentResolver.openInputStream(documentUri)?.use { it.readBytes() }
                    ?: throw FileNotFoundException("O arquivo não pôde ser aberto.")
            }
            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        safExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun selectFolder(result: MethodChannel.Result) {
        if (pendingSelection != null) {
            result.error("selection_in_progress", "Já existe uma seleção de pasta em andamento.", null)
            return
        }
        pendingSelection = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        startActivityForResult(intent, REQUEST_OPEN_DOCUMENT_TREE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_OPEN_DOCUMENT_TREE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingSelection ?: return
        pendingSelection = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val treeUri = data.data!!
        val offeredFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (offeredFlags == 0) {
            result.error(
                "persist_permission_failed",
                "O provedor não concedeu autorização de leitura persistente.",
                null,
            )
            return
        }

        try {
            contentResolver.takePersistableUriPermission(treeUri, offeredFlags)
            val name = queryTreeName(treeUri)
            result.success(mapOf("uri" to treeUri.toString(), "nome" to name))
        } catch (error: SecurityException) {
            result.error(
                "persist_permission_failed",
                "Não foi possível preservar a autorização da pasta selecionada.",
                error.message,
            )
        } catch (error: Exception) {
            sendSafError(result, error)
        }
    }

    private fun requiredUri(call: MethodCall, key: String): Uri {
        val value = call.argument<String>(key)
            ?: throw IllegalArgumentException("Identificador da pasta ou documento ausente.")
        return Uri.parse(value)
    }

    private fun requirePersistedReadPermission(treeUri: Uri) {
        val permitted = contentResolver.persistedUriPermissions.any {
            it.uri == treeUri && it.isReadPermission
        }
        if (!permitted) {
            throw SecurityException("A autorização persistente da pasta foi revogada.")
        }
    }

    private fun queryTreeName(treeUri: Uri): String? {
        val documentId = DocumentsContract.getTreeDocumentId(treeUri)
        val documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
        val cursor = contentResolver.query(
            documentUri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        ) ?: throw FileNotFoundException("O provedor não retornou a pasta selecionada.")
        return cursor.use {
            if (!cursor.moveToFirst()) {
                null
            } else {
                cursor.optionalString(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            }
        }
    }

    private fun listDirectChildrenAsync(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = try {
            requiredUri(call, "uri").also(::requirePersistedReadPermission)
        } catch (error: Exception) {
            sendSafError(result, error)
            return
        }
        safExecutor.execute {
            try {
                val enumeration = listDirectChildren(treeUri)
                runOnUiThread { result.success(enumeration) }
            } catch (error: Exception) {
                runOnUiThread { sendSafError(result, error) }
            }
        }
    }

    private fun listDirectChildren(treeUri: Uri): Map<String, Any?> {
        val parentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_FLAGS,
        )
        val changes = LinkedBlockingQueue<Unit>()
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                changes.offer(Unit)
            }

            override fun onChange(selfChange: Boolean, uri: Uri?) {
                changes.offer(Unit)
            }
        }
        val observedUris = mutableSetOf<Uri>()
        fun observe(uri: Uri?) {
            if (uri != null && observedUris.add(uri)) {
                contentResolver.registerContentObserver(uri, false, observer)
            }
        }
        observe(childrenUri)
        try {
            var queryCount = 0
            fun query(): SafEnumerationSnapshot<Map<String, Any?>> {
                queryCount++
                return queryDirectChildren(
                    treeUri = treeUri,
                    childrenUri = childrenUri,
                    projection = projection,
                ).also { snapshot ->
                    observe(snapshot.notificationUri?.let(Uri::parse))
                }
            }
            val outcome = enumerationCoordinator.enumerate(
                query = ::query,
                awaitChange = { timeoutMillis ->
                    changes.poll(timeoutMillis, TimeUnit.MILLISECONDS) != null
                },
            )
            val snapshot = outcome.snapshot
            val directories = snapshot.items.count { it["ehDiretorio"] == true }
            val files = snapshot.items.size - directories
            val choFiles = snapshot.items.count {
                it["ehDiretorio"] == false &&
                    (it["nome"] as String).endsWith(".cho", ignoreCase = true)
            }
            val folderName = runCatching { queryTreeName(treeUri) }.getOrNull()
            logSaf {
                "resultado treeUri=$treeUri documentId=$parentId nome=$folderName " +
                    "linhas=${snapshot.items.size} diretorios=$directories arquivos=$files " +
                    "cho=$choFiles completa=${outcome.complete} loading=${snapshot.loading} " +
                    "consultas=$queryCount timeout=${outcome.timedOut} " +
                    "notificationUri=${snapshot.notificationUri} " +
                    "erro=${snapshot.providerError}"
            }
            return mapOf(
                "documentos" to snapshot.items,
                "completa" to outcome.complete,
                "tentativas" to queryCount,
                "carregando" to snapshot.loading,
                "linhasBrutas" to snapshot.items.size,
                "diretorios" to directories,
                "arquivos" to files,
                "arquivosCho" to choFiles,
                "uriArvore" to treeUri.toString(),
                "documentId" to parentId,
                "nomePasta" to folderName,
                "erroProvider" to snapshot.providerError,
            )
        } finally {
            contentResolver.unregisterContentObserver(observer)
        }
    }

    private fun queryDirectChildren(
        treeUri: Uri,
        childrenUri: Uri,
        projection: Array<String>,
    ): SafEnumerationSnapshot<Map<String, Any?>> {
        return queryDirectChildrenCursor(childrenUri, projection).use { cursor ->
            readDirectChildrenCursor(treeUri, childrenUri, cursor)
        }
    }

    private fun queryDirectChildrenCursor(
        childrenUri: Uri,
        projection: Array<String>,
    ): Cursor = contentResolver.query(childrenUri, projection, null, null, null)
        ?: throw FileNotFoundException("O provedor não retornou os filhos da pasta.")

    private fun readDirectChildrenCursor(
        treeUri: Uri,
        childrenUri: Uri,
        cursor: Cursor,
    ): SafEnumerationSnapshot<Map<String, Any?>> {
        val extras = cursor.extras
        val loading = extras.getBoolean(DocumentsContract.EXTRA_LOADING, false)
        val providerError = extras.getString(DocumentsContract.EXTRA_ERROR)
        val providerInfo = extras.getString(DocumentsContract.EXTRA_INFO)
        val notificationUri = cursor.notificationUri
            ?: extras.notificationUriCompat(DOCUMENTS_UI_NOTIFICATION_URI)
        val rawCount = cursor.count
        val honoredArgs = extras.getStringArray(ContentResolver.EXTRA_HONORED_ARGS)
        val totalCount = if (extras.containsKey(ContentResolver.EXTRA_TOTAL_COUNT)) {
            extras.getInt(ContentResolver.EXTRA_TOTAL_COUNT)
        } else {
            null
        }
        val documents = buildList {
            while (cursor.moveToNext()) {
                val documentId = cursor.requiredString(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                )
                val name = cursor.optionalString(
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                ) ?: documentId
                val mimeType = cursor.optionalString(
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                )
                val flags = cursor.optionalInt(DocumentsContract.Document.COLUMN_FLAGS) ?: 0
                val isDirectory = mimeType == DocumentsContract.Document.MIME_TYPE_DIR
                val isVirtual = flags and DocumentsContract.Document.FLAG_VIRTUAL_DOCUMENT != 0
                val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                    treeUri,
                    documentId,
                )
                logSaf {
                    "documento nome=$name documentId=$documentId mime=$mimeType " +
                        "diretorio=$isDirectory virtual=$isVirtual uri=$documentUri"
                }
                add(
                    mapOf(
                        "localizador" to documentUri.toString(),
                        "nome" to name,
                        "tipoMime" to mimeType,
                        "ehDiretorio" to isDirectory,
                    ),
                )
            }
        }
        logSaf {
            "consulta uri=$childrenUri linhasBrutas=$rawCount documentos=${documents.size} " +
                "loading=$loading info=$providerInfo erro=$providerError " +
                "notificationUri=$notificationUri honoredArgs=${honoredArgs?.contentToString()} " +
                "totalCount=$totalCount chavesExtras=${extras.keySet().sorted()}"
        }
        return SafEnumerationSnapshot(
            items = documents,
            loading = loading,
            providerError = providerError,
            notificationUri = notificationUri?.toString(),
        )
    }

    @Suppress("DEPRECATION")
    private fun android.os.Bundle.notificationUriCompat(key: String): Uri? =
        getParcelable(key) as? Uri

    private fun Cursor.requiredString(column: String): String =
        getString(getColumnIndexOrThrow(column))

    private fun Cursor.optionalString(column: String): String? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getString(index)
    }

    private fun Cursor.optionalInt(column: String): Int? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getInt(index)
    }

    private inline fun logSaf(message: () -> String) {
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            Log.d(LOG_TAG, message())
        }
    }

    private inline fun withSafErrors(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        try {
            result.success(operation())
        } catch (error: Exception) {
            sendSafError(result, error)
        }
    }

    private fun sendSafError(result: MethodChannel.Result, error: Exception) {
        val code = when (error) {
            is SecurityException -> "access_revoked"
            is FileNotFoundException,
            is IllegalArgumentException,
            is UnsupportedOperationException -> "provider_unavailable"
            else -> "read_error"
        }
        val message = when (code) {
            "access_revoked" -> "A autorização de acesso à pasta foi perdida ou revogada."
            "provider_unavailable" -> "O provedor da pasta não está disponível no momento."
            else -> "Não foi possível ler a pasta ou o arquivo selecionado."
        }
        result.error(code, message, error.message)
    }
}
