;;; kotlin-ts-mode.el --- A mode for editing Kotlin files based on tree-sitter

;; Author: Alex Figl-Brick <alex@alexbrick.me>
;; Package-Requires: ((tree-sitter) (tree-sitter-indent))

;;; Commentary:

;;; Code:

(require 'tree-sitter-hl)
(require 'tree-sitter-indent)

(defvar kotlin-mode-syntax-table
  (let ((st (make-syntax-table)))

    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\' "\"" st)
    (modify-syntax-entry ?` "\"" st)

    ;; `_' and `@' as being a valid part of a symbol
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?@ "_" st)

    ;; b-style comment
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23n" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\r "> b" st)
    st))

;; Taken from https://github.com/fwcd/tree-sitter-kotlin/pull/50
;; Updated to match Emacs style
(defconst kotlin-ts-mode-tree-sitter-patterns
  [
;;; Identifiers

; `it` keyword inside lambdas
; FIXME: This will highlight the keyword outside of lambdas since tree-sitter
;        does not allow us to check for arbitrary nestation
((simple_identifier) @variable.builtin
(\.eq? @variable.builtin "it"))

; `field` keyword inside property getter/setter
; FIXME: This will highlight the keyword outside of getters and setters
;        since tree-sitter does not allow us to check for arbitrary nestation
((simple_identifier) @variable.builtin
(\.eq? @variable.builtin "field"))

; `this` this keyword inside classes
(this_expression) @variable.builtin

; `super` keyword inside classes
(super_expression) @variable.builtin

(class_parameter "val" @keyword)
(class_parameter
	(simple_identifier) @property)

(class_body
	(property_declaration
		(variable_declaration
			(simple_identifier) @property)))

; id_1.id_2.id_3: `id_2` and `id_3` are assumed as object properties
(_
	(navigation_suffix
		(simple_identifier) @property))

(enum_entry
	(simple_identifier) @constant)

(type_identifier) @type

((type_identifier) @type.builtin
	(\.any-of? @type.builtin
		"Byte"
		"Short"
		"Int"
		"Long"
		"UByte"
		"UShort"
		"UInt"
		"ULong"
		"Float"
		"Double"
		"Boolean"
		"Char"
		"String"
		"Array"
		"ByteArray"
		"ShortArray"
		"IntArray"
		"LongArray"
		"UByteArray"
		"UShortArray"
		"UIntArray"
		"ULongArray"
		"FloatArray"
		"DoubleArray"
		"BooleanArray"
		"CharArray"
		"Map"
		"Set"
		"List"
		"EmptyMap"
		"EmptySet"
		"EmptyList"
		"MutableMap"
		"MutableSet"
		"MutableList"
))

(package_header
 "package" @keyword
	(identifier))

(import_header
	"import" @keyword)


; TODO: Seperate labeled returns/breaks/continue/super/this
;       Must be implemented in the parser first
(label) @label

;;; Function definitions

(function_declaration
	\. (simple_identifier) @function)

(getter
	("get") @function.builtin)
(setter
	("set") @function.builtin)

(primary_constructor) @constructor
(secondary_constructor
	("constructor") @constructor)

(constructor_invocation
	(user_type
		(type_identifier) @constructor))

(anonymous_initializer
	("init") @constructor)

(parameter
	(simple_identifier) @variable.parameter)

(parameter_with_optional_type
	(simple_identifier) @variable.parameter)

; lambda parameters
(lambda_literal
	(lambda_parameters
		(variable_declaration
			(simple_identifier) @variable.parameter)))

;;; Function calls

; function()
(call_expression
	\. (simple_identifier) @function.call)

; object.function() or object.property.function()
(call_expression
	(navigation_expression
		(navigation_suffix
			(simple_identifier) @method.call) \. ))

(call_expression
	\. (simple_identifier) @function.builtin
    (\.any-of? @function.builtin
		"arrayOf"
		"arrayOfNulls"
		"byteArrayOf"
		"shortArrayOf"
		"intArrayOf"
		"longArrayOf"
		"ubyteArrayOf"
		"ushortArrayOf"
		"uintArrayOf"
		"ulongArrayOf"
		"floatArrayOf"
		"doubleArrayOf"
		"booleanArrayOf"
		"charArrayOf"
		"emptyArray"
		"mapOf"
		"setOf"
		"listOf"
		"emptyMap"
		"emptySet"
		"emptyList"
		"mutableMapOf"
		"mutableSetOf"
		"mutableListOf"
		"print"
		"println"
		"error"
		"TODO"
		"run"
		"runCatching"
		"repeat"
		"lazy"
		"lazyOf"
		"enumValues"
		"enumValueOf"
		"assert"
		"check"
		"checkNotNull"
		"require"
		"requireNotNull"
		"with"
		"suspend"
		"synchronized"
))

;;; Literals

[
	(comment)
	(shebang_line)
] @comment

(real_literal) @number
[
	(integer_literal)
	(long_literal)
	(hex_literal)
	(bin_literal)
	(unsigned_literal)
] @number

[
	"null" ; should be highlighted the same as booleans
	(boolean_literal)
] @type.builtin

(character_literal) @string

[
	(line_string_literal)
	(multi_line_string_literal)
] @string

; NOTE: Escapes not allowed in multi-line strings
(line_string_literal (character_escape_seq) @escape)

; There are 3 ways to define a regex
;    - "[abc]?".toRegex()
(call_expression
	(navigation_expression
		([(line_string_literal) (multi_line_string_literal)] @string.special)
		(navigation_suffix
			((simple_identifier) @_function
			(\.eq? @_function "toRegex")))))

;    - Regex("[abc]?")
(call_expression
	((simple_identifier) @_function
	(\.eq? @_function "Regex"))
	(call_suffix
		(value_arguments
			(value_argument
				[ (line_string_literal) (multi_line_string_literal) ] @string.special))))

;    - Regex.fromLiteral("[abc]?")
(call_expression
	(navigation_expression
		((simple_identifier) @_class
		(\.eq? @_class "Regex"))
		(navigation_suffix
			((simple_identifier) @_function
			(\.eq? @_function "fromLiteral"))))
	(call_suffix
		(value_arguments
			(value_argument
				[ (line_string_literal) (multi_line_string_literal) ] @string.special))))

;;; Keywords

(type_alias "typealias" @keyword)
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
]@keyword

[
	"val"
	"var"
	"enum"
	"class"
	"object"
	"interface"
;	"typeof" ; NOTE: It is reserved for future use
] @keyword

("fun") @keyword

(jump_expression
 ["throw" "return" "return@" "continue" "continue@" "break" "break@"] @keyword)

[
	"if"
	"else"
	"when"
] @keyword

[
	"for"
	"do"
	"while"
] @keyword

[
	"try"
	"catch"
	"throw"
	"finally"
] @keyword


(annotation
	"@" @attribute (use_site_target) @attribute)
(annotation
	(user_type
		(type_identifier) @attribute))
(annotation
	(constructor_invocation
		(user_type
			(type_identifier) @attribute)))

(file_annotation
	"@" @attribute "file" @attribute ":" @attribute)
(file_annotation
	(user_type
		(type_identifier) @attribute))
(file_annotation
	(constructor_invocation
		(user_type
			(type_identifier) @attribute)))

;;; Operators & Punctuation

[
	"!"
	"!="
	"!=="
	"="
	"=="
	"==="
	">"
	">="
	"<"
	"<="
	"||"
	"&&"
	"+"
	"++"
	"+="
	"-"
	"--"
	"-="
	"*"
	"*="
	"/"
	"/="
	"%"
	"%="
	"?."
	"?:"
	"!!"
	"is"
	"!is"
	"in"
	"!in"
	"as"
	"as?"
	".."
	"->"
] @operator

[
	"(" ")"
	"[" "]"
	"{" "}"
] @punctuation.bracket

[
	"."
	","
	";"
	":"
	"::"
] @punctuation.delimiter

; NOTE: `interpolated_identifier`s can be highlighted in any way
(line_string_literal
	"$" @punctuation.special
	(interpolated_identifier) @none)
(line_string_literal
	"${" @punctuation.special
	(interpolated_expression) @none
	"}" @punctuation.special)

(multi_line_string_literal
    "$" @punctuation.special
    (interpolated_identifier) @none)
(multi_line_string_literal
	"${" @punctuation.special
	(interpolated_expression) @none
	"}" @punctuation.special)

   ]
  )

(defvar kotlin-ts-indent-offset 4 "How far to indent in `kotlin-mode'.")

(defconst tree-sitter-indent-kotlin-ts-scopes
  '((indent-body . (block)))
  )

(define-derived-mode kotlin-ts-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin using tree-sitter."

  (setq-local comment-start "//"
              comment-padding 1
              comment-start-skip "\\(//+\\|/\\*+\\)\\s *"
              comment-end "")

  ;; Syntax Highlighting
  (setq-local tree-sitter-hl-default-patterns kotlin-ts-mode-tree-sitter-patterns)
  (tree-sitter-hl-mode)

  ;; Indentation
  (setq-local indent-line-function #'tree-sitter-indent-line)
  (tree-sitter-indent-mode)

  :syntax-table kotlin-mode-syntax-table
  )

(add-to-list 'tree-sitter-major-mode-language-alist '(kotlin-ts-mode . kotlin))

(provide 'kotlin-ts-mode)
;;; kotlin-ts-mode.el ends here
