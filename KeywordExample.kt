package test

import java.util.UUID

class Foo<A> where A : B, A : C

class Foo : A by a()

class Foo {
    init {
    }
}

class Foo {
    val f: suspend () -> Unit = suspend { a() }
}

fun foo() {
    val x = a as A
    val y = b is B
}

class Foo {
    private fun foo() {
        try {
            val bar = UUID.randomValue()
            this.hello()
            super.goodbye()
        } catch (e: Exception) {
            println("Catch")
        } finally {
            println("Finally")
        }

        while (true) {
            break
        }

        do {
            continue
        } while (true)

        if (true) {
            return@map
        } else {
            throw RuntimeException("Universe is broken")
        }

        if (a !is String) {
            return 1
        }

        return mapOf(
            a to b,
        )
    }
}
