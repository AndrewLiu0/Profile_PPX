(lang dune 3.0)

(generate_opam_files true)

(package
 (name profile_ppx)
 (depends
  (ocaml
   (>= 5.2.0))
  dune
  ocaml-lsp-server
  ocamlformat
  ppxlib
  core
  ppx_jane
  (expect_test_helpers_core :with-test)))
