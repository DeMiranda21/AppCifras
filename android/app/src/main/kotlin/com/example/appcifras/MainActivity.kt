package com.example.appcifras

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "appcifras/pasta_curada"
        private const val REQUEST_OPEN_DOCUMENT_TREE = 4103
    }

    private var pendingSelection: MethodChannel.Result? = null

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
            "listarFilhosDiretos" -> withSafErrors(result) {
                val treeUri = requiredUri(call, "uri")
                requirePersistedReadPermission(treeUri)
                listDirectChildren(treeUri)
            }
            "lerBytes" -> withSafErrors(result) {
                val documentUri = requiredUri(call, "localizador")
                contentResolver.openInputStream(documentUri)?.use { it.readBytes() }
                    ?: throw FileNotFoundException("O arquivo não pôde ser aberto.")
            }
            else -> result.notImplemented()
        }
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

    private fun listDirectChildren(treeUri: Uri): List<Map<String, Any?>> {
        val parentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )
        return contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            buildList {
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
                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                        treeUri,
                        documentId,
                    )
                    add(
                        mapOf(
                            "localizador" to documentUri.toString(),
                            "nome" to name,
                            "tipoMime" to mimeType,
                            "ehDiretorio" to
                                (mimeType == DocumentsContract.Document.MIME_TYPE_DIR),
                        ),
                    )
                }
            }
        } ?: throw FileNotFoundException("O provedor não retornou os filhos da pasta.")
    }

    private fun Cursor.requiredString(column: String): String =
        getString(getColumnIndexOrThrow(column))

    private fun Cursor.optionalString(column: String): String? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getString(index)
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
