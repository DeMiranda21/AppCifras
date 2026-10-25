package com.example.appcifras

internal data class SafEnumerationSnapshot<T>(
    val items: List<T>,
    val loading: Boolean,
    val providerError: String? = null,
    val notificationUri: String? = null,
)

internal data class SafEnumerationOutcome<T>(
    val snapshot: SafEnumerationSnapshot<T>,
    val complete: Boolean,
    val attempts: Int,
    val timedOut: Boolean,
)

internal class SafEnumerationCoordinator(
    private val timeoutMillis: Long = 15_000,
    private val maxAttempts: Int = 8,
    private val nowMillis: () -> Long = System::currentTimeMillis,
) {
    init {
        require(timeoutMillis > 0)
        require(maxAttempts > 0)
    }

    fun <T> enumerate(
        initialSnapshot: SafEnumerationSnapshot<T>? = null,
        query: () -> SafEnumerationSnapshot<T>,
        awaitChange: (timeoutMillis: Long) -> Boolean,
    ): SafEnumerationOutcome<T> {
        val deadline = nowMillis() + timeoutMillis
        var attempts = 0
        var lastSnapshot: SafEnumerationSnapshot<T>? = initialSnapshot

        while (true) {
            attempts++
            lastSnapshot = lastSnapshot ?: query()
            if (!lastSnapshot.loading && lastSnapshot.providerError == null) {
                return SafEnumerationOutcome(
                    snapshot = lastSnapshot,
                    complete = true,
                    attempts = attempts,
                    timedOut = false,
                )
            }
            if (lastSnapshot.providerError != null || attempts >= maxAttempts) {
                return SafEnumerationOutcome(
                    snapshot = lastSnapshot,
                    complete = false,
                    attempts = attempts,
                    timedOut = false,
                )
            }

            val remaining = deadline - nowMillis()
            if (remaining <= 0 || !awaitChange(remaining)) {
                return SafEnumerationOutcome(
                    snapshot = lastSnapshot,
                    complete = false,
                    attempts = attempts,
                    timedOut = true,
                )
            }
            lastSnapshot = null
        }
    }
}
