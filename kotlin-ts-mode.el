;;; kotlin-ts-mode.el --- A mode for editing Kotlin files based on tree-sitter  -*- lexical-binding: t; -*-

;; Copyright 2022 Alex Figl-Brick

;; Author: Alex Figl-Brick <alex@alexbrick.me>
;; Package-Requires: ((emacs "29"))
;; URL: https://gitlab.com/bricka/emacs-kotlin-ts-mode

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package uses the `treesit' functionality added in Emacs 29 to
;; provide a nice mode for editing Kotlin code.

;;; Code:

(require 'treesit)
(require 'c-ts-mode) ; For comment indent and filling.

(defvar kotlin-ts-mode-indent-offset 4)

(defvar kotlin-ts-mode-syntax-table
  (let ((st (make-syntax-table)))

    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\' "\"" st)
    (modify-syntax-entry ?` "\"" st)

    ;; `_' and `@' as being a valid part of a symbol
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?@ "_" st)

    ;; b-style comment
    (modify-syntax-entry ?/ ". 124" st)
    (modify-syntax-entry ?* ". 23b" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\r "> b" st)
    st))

;; Based on https://github.com/fwcd/tree-sitter-kotlin/pull/50
(defconst kotlin-ts-mode--treesit-settings
  (treesit-font-lock-rules
   :language 'kotlin
   :feature 'keyword
   '(;; `it` keyword inside lambdas
     ;; FIXME: This will highlight the keyword outside of lambdas since tree-sitter
     ;;        does not allow us to check for arbitrary nestation
     ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "it"))

     ;; `field` keyword inside property getter/setter
     ;; FIXME: This will highlight the keyword outside of getters and setters
     ;;        since tree-sitter does not allow us to check for arbitrary nestation
     ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "field"))

     ;; `this` this keyword inside classes
     (this_expression "this") @font-lock-keyword-face

     ;; `super` keyword inside classes
     (super_expression) @font-lock-keyword-face

     ["val" "var" "enum" "class" "object" "interface"] @font-lock-keyword-face

     (package_header "package" @font-lock-keyword-face)

     (import_header "import" @font-lock-keyword-face)

     (type_alias "typealias" @font-lock-keyword-face)
     [
      (class_modifier)
      (member_modifier)
      (function_modifier)
      (property_modifier)
      (platform_modifier)
      (variance_modifier)
      (parameter_modifier)
      (visibility_modifier)
      (reification_modifier)
      (inheritance_modifier)
      ] @font-lock-keyword-face

     (companion_object "companion" @font-lock-keyword-face)
     (function_declaration "fun" @font-lock-keyword-face)

     (jump_expression ["throw" "return" "return@" "continue" "continue@" "break" "break@"] @font-lock-keyword-face)

     ["if" "else" "when"] @font-lock-keyword-face

     ["for" "do" "while" "in"] @font-lock-keyword-face

     ["try" "catch" "throw" "finally"] @font-lock-keyword-face

     (type_test "is" @font-lock-keyword-face)

     (prefix_expression "!" @font-lock-negation-char-face))

   :language 'kotlin
   :feature 'comment
   '([(comment) (shebang_line)] @font-lock-comment-face)

   :language 'kotlin
   :feature 'string
   '((character_literal) @font-lock-string-face
     [(line_string_literal) (multi_line_string_literal)] @font-lock-string-face)

   :language 'kotlin
   :feature 'definition
   '((function_declaration (simple_identifier) @font-lock-function-name-face)
     (parameter (simple_identifier) @font-lock-variable-name-face)
     (class_parameter (simple_identifier) @font-lock-variable-name-face)
     (variable_declaration (simple_identifier) @font-lock-variable-name-face))

   :language 'kotlin
   :feature 'number
   '([(integer_literal) (long_literal) (hex_literal) (bin_literal) (unsigned_literal) (real_literal)] @font-lock-number-face)

   :language 'kotlin
   :feature 'type
   '((type_identifier) @font-lock-type-face
     (call_expression (simple_identifier) @font-lock-type-face
                      (:match "^[A-Z]" @font-lock-type-face)))

   :language 'kotlin
   :feature 'constant
   '(["null" (boolean_literal)] @font-lock-constant-face)


   :language 'kotlin
   :feature 'builtin
   '((call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "listOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "arrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "arrayOfNulls"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "byteArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "shortArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "intArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "longArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ubyteArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ushortArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "uintArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ulongArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "floatArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "doubleArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "booleanArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "charArrayOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyArray"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mapOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "setOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "listOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyMap"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptySet"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyList"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableMapOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableSetOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableListOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "print"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "println"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "error"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "TODO"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "run"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "runCatching"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "repeat"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "lazy"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "lazyOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "enumValues"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "enumValueOf"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "assert"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "check"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "checkNotNull"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "require"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "requireNotNull"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "with"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "suspend"))
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "synchronized")))))

(defconst kotlin-ts-mode--treesit-indent-rules
  (let ((offset kotlin-ts-mode-indent-offset))
    `((kotlin
       ((node-is "}") parent-bol 0)
       ((node-is ")") parent-bol 0)
       ((parent-is "statements") parent-bol 0)
       ((parent-is "class_body") parent-bol ,offset)
       ((parent-is "control_structure_body") parent-bol ,offset)
       ((parent-is "function_body") parent-bol ,offset)
       ((parent-is "lambda_literal") parent-bol ,offset)
       ((parent-is "value_arguments") parent-bol ,offset)
       ((parent-is "comment") parent-bol 1)))))

(defun kotlin-ts-mode-goto-test-file ()
  "Go from the current file to the test file."
  (interactive)
  (if (not (string-match-p (regexp-quote "src/main/kotlin") (buffer-file-name)))
      (warn "Could not find test file for %s" (buffer-file-name))
    (let* ((test-directory (file-name-directory (string-replace "src/main/kotlin" "src/test/kotlin" (buffer-file-name))))
           (file-name-as-test (concat (file-name-base (buffer-file-name)) "Test.kt"))
           (test-file-location (concat test-directory file-name-as-test)))
      (find-file test-file-location))))

(define-derived-mode kotlin-ts-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin using tree-sitter."
  (treesit-parser-create 'kotlin)

  ;; Comments
  (c-ts-mode-comment-setup)

  ;; Electric
  (setq-local electric-indent-chars
              (append "{}():;," electric-indent-chars))

  ;; Syntax Highlighting
  (setq-local treesit-font-lock-settings kotlin-ts-mode--treesit-settings)
  (setq-local treesit-font-lock-feature-list '((comment number string definition)
                                               (class-name keyword builtin type constant)
                                               (string-interpolation decorator)))

  ;; Indent
  (setq-local treesit-simple-indent-rules kotlin-ts-mode--treesit-indent-rules)

  (treesit-major-mode-setup)

  :syntax-table kotlin-ts-mode-syntax-table)

(provide 'kotlin-ts-mode)
;;; kotlin-ts-mode.el ends here
