(require 'kotlin-ts-mode)

(ert-deftest kotlin-ts-mode--indent-classes-and-functions ()
  "Test that functions and classes are indented properly."
  (kotlin-ts-mode--test-indentation "class Foo {
fun bar() {}
class Baz {
fun bar2() {
}
}
}"
                                    "class Foo {
    fun bar() {}
    class Baz {
        fun bar2() {
        }
    }
}"))

(ert-deftest kotlin-ts-mode--indent-multiline-function-calls ()
  "Test that multiline function calls are indented correctly."
  (kotlin-ts-mode--test-indentation "val foo = foo()
.bar()
.baz(
\"hello\"
)"
                                    "val foo = foo()
    .bar()
    .baz(
        \"hello\"
    )")
  )

(defun kotlin-ts-mode--test-indentation (unindented indented)
  "Test that after indentation, UNINDENTED looks like INDENTED."
  (with-temp-buffer
    (insert unindented)
    (kotlin-ts-mode)
    (setq-local indent-tabs-mode nil)
    (indent-region (point-min) (point-max))
    (should (equal (buffer-string) indented))))
