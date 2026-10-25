package com.example.appcifras

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SafEnumerationCoordinatorTest {
    @Test
    fun completeOnFirstQuery() {
        val result = SafEnumerationCoordinator().enumerate(
            query = { SafEnumerationSnapshot(listOf("a", "b"), loading = false) },
            awaitChange = { error("não deveria aguardar") },
        )

        assertTrue(result.complete)
        assertEquals(listOf("a", "b"), result.snapshot.items)
        assertEquals(1, result.attempts)
    }

    @Test
    fun waitsForNotificationBeforeRequeryingPartialResult() {
        val snapshots = ArrayDeque(
            listOf(
                SafEnumerationSnapshot(listOf("antigo-1", "antigo-2"), loading = true),
                SafEnumerationSnapshot(
                    listOf("antigo-1", "antigo-2", "novo"),
                    loading = false,
                ),
            ),
        )
        var notifications = 0

        val result = SafEnumerationCoordinator().enumerate(
            query = { snapshots.removeFirst() },
            awaitChange = {
                notifications++
                true
            },
        )

        assertTrue(result.complete)
        assertEquals(1, notifications)
        assertEquals(3, result.snapshot.items.size)
        assertEquals(2, result.attempts)
    }

    @Test
    fun supportsMultiplePartialUpdates() {
        val snapshots = ArrayDeque(
            listOf(
                SafEnumerationSnapshot(listOf("a"), loading = true),
                SafEnumerationSnapshot(listOf("a", "b"), loading = true),
                SafEnumerationSnapshot(listOf("a", "b", "c"), loading = false),
            ),
        )

        val result = SafEnumerationCoordinator(maxAttempts = 4).enumerate(
            query = { snapshots.removeFirst() },
            awaitChange = { true },
        )

        assertTrue(result.complete)
        assertEquals(listOf("a", "b", "c"), result.snapshot.items)
        assertEquals(3, result.attempts)
    }

    @Test
    fun timeoutKeepsLastPartialResultIncomplete() {
        var now = 1_000L
        val result = SafEnumerationCoordinator(
            timeoutMillis = 500,
            nowMillis = { now },
        ).enumerate(
            query = { SafEnumerationSnapshot(listOf("cache-1", "cache-2"), loading = true) },
            awaitChange = { timeout ->
                now += timeout
                false
            },
        )

        assertFalse(result.complete)
        assertTrue(result.timedOut)
        assertEquals(listOf("cache-1", "cache-2"), result.snapshot.items)
        assertEquals(1, result.attempts)
    }

    @Test
    fun attemptLimitStopsProviderThatKeepsLoading() {
        val result = SafEnumerationCoordinator(maxAttempts = 3).enumerate(
            query = { SafEnumerationSnapshot(listOf("parcial"), loading = true) },
            awaitChange = { true },
        )

        assertFalse(result.complete)
        assertFalse(result.timedOut)
        assertEquals(3, result.attempts)
    }
}
