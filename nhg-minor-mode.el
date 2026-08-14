;;; nhg-minor-mode.el --- 日本語の文章を書くためのハイライト  -*- lexical-binding: t; -*-

(require 'font-lock)

;; -------------------------------------------------------------------------
;; 1. Face (色の定義: オリジナルの色味を再現)
;; -------------------------------------------------------------------------

(defgroup nhg-mode nil
  "Faces and settings for nhg-mode."
  :group 'font-lock)

;; section01: "これ/それ" など (赤系)
(defface nhg-section-face-01
  '((((class color) (background dark))  (:foreground "tomato"))
    (((class color) (background light)) (:foreground "red")))
  "Face for demonstratives (kosoado)."
  :group 'nhg-mode)

;; section03: "#title:" (シアン系)
(defface nhg-section-face-03
  '((((class color) (background dark))  (:foreground "light cyan" :height 1.2))
    (((class color) (background light)) (:foreground "DarkCyan" :height 1.2)))
  "Face for titles."
  :group 'nhg-mode)

;; operator01: 警告・強調など (青系)
(defface nhg-operator-face-01
  '((((class color) (background dark))  (:foreground "light sky blue"))
    (((class color) (background light)) (:foreground "blue")))
  "Face for operators 01."
  :group 'nhg-mode)

;; operator02: "ます/です" (紫系)
(defface nhg-operator-face-02
  '((((class color) (background dark))  (:foreground "orchid"))
    (((class color) (background light)) (:foreground "purple")))
  "Face for operators 02."
  :group 'nhg-mode)

;; type01: "しかし/けれど" (茶色系 - Sienna)
(defface nhg-type-face-01
  '((((class color) (background dark))  (:foreground "burlywood1"))
    (((class color) (background light)) (:foreground "sienna")))
  "Face for conjunctions type 01."
  :group 'nhg-mode)

;; type02: "である/っぽい" (カーキ系 - Khaki)
(defface nhg-type-face-02
  '((((class color) (background dark))  (:foreground "khaki"))
    (((class color) (background light)) (:foreground "khaki4")))
  "Face for conjunctions type 02."
  :group 'nhg-mode)

;; -------------------------------------------------------------------------
;; 2. Keywords (ハイライト設定)
;; -------------------------------------------------------------------------

(defconst nhg-regex-pronoun
  (regexp-opt
   '("これ" "ここ" "この" "こう" "こんな"
     "それ" "そこ" "その" "そう" "そんな"
     "あれ" "あそこ" "あの" "あんな"
     "どれ" "どこ" "どの" "どう" "どんな"
     "もの")
   t))

(defconst nhg-regex-endings
  (regexp-opt
   '("ます。" "です。" "なる。" "なのだ。" "ない。" "いる。" "だ。")
   t))

(defconst nhg-regex-conjunction-strong
  (regexp-opt
   '("れる。" "れた。" "例えば" "しかし" "けれど" "だから" "なるほど"
     "ところが" "だが" "もっとも" "ともあれ" "けど" "時に" "ただし"
     "こと" "でもない" "が、" "で、" )
   t))

(defconst nhg-regex-conjunction-weak
  (regexp-opt
   '("である。" "っぽい" "それで" "感じ" "的"
     "というか" "もちろん" "そんなわけで" "思う" "なって")
   t))

(defconst nhg-font-lock-keywords
  (list
   ;; 1. タイトル (#title: ...) -> Section 03 (DarkCyan)
   '("^#title: .*" 0 'nhg-section-face-03)

   ;; 2. こそあど (これ/それ) -> Section 01 (Red/Tomato)
   `(,nhg-regex-pronoun 0 'nhg-section-face-01)
   '("よう\\(?:に\\|な\\)" 0 'nhg-section-face-01)

   ;; 3. 語尾 (ます/です) -> Operator 02 (Purple)
   `(,nhg-regex-endings 0 'nhg-operator-face-02)

   ;; 4. 接続詞・型1 (しかし/例えば) -> Type 01 (Sienna)
   `(,nhg-regex-conjunction-strong 0 'nhg-type-face-01)
   '("『[^』]*』" 0 'nhg-type-face-01)
   '("気\\(?:の\\|が\\|も\\)" 0 'nhg-type-face-01)

   ;; 5. 接続詞・型2 (である/っぽい) -> Type 02 (Khaki)
   `(,nhg-regex-conjunction-weak 0 'nhg-type-face-02)

   ;; 6. 警告・強調 -> Operator 01 (Blue)
   ;; 長いひらがな (24文字以上)
   '("\\([あ-ん]\\{24,\\}\\)" 1 'nhg-operator-face-01)
   ;; 重複する助詞 (てて、のを、がが etc)
   '("\\([てをがにはのばで]\\)\\1" 0 'nhg-operator-face-01)
   
   ;; 数字で終わる行をすべて青くする。
   ;; 行頭 ^ で固定しないと行内の全位置で .* が行末まで走ってから
   ;; 後戻りするため、長い行ほど急激に重くなる (着色結果は同じ)。
   ;; 画面全体が青くなるのが煩わしい場合は行頭に ; を付けて無効化する。
   '("^.*[0-9]$" 0 'nhg-operator-face-01)

   ;; 7. 一般キーワード (define etc)
   `(,(regexp-opt '("define" "include" "postProcess" "filepath") 'words)
     0 font-lock-keyword-face)

   ;; 8. タグ (:tag1:tag2:...:) -> Operator 02 (Purple)
   '(":[^:\n0-9][^:\n]*\\(?::[^:\n0-9][^:\n]*\\)*:" 0 'nhg-operator-face-02)
   ))

;; -------------------------------------------------------------------------
;; 3. Mode Definition
;; -------------------------------------------------------------------------

(define-minor-mode nhg-minor-mode
  "Minor mode for nhg styling."
  :lighter " nhg"
  (if nhg-minor-mode
      (progn
        (font-lock-add-keywords nil nhg-font-lock-keywords 'append)
        (setq-local tab-width 2)
        (setq-local indent-tabs-mode nil))
    (font-lock-remove-keywords nil nhg-font-lock-keywords))
  
  ;; font-lock-flush は Emacs 25.1 以降で常に存在する。
  (font-lock-flush))

(provide 'nhg-minor-mode)
