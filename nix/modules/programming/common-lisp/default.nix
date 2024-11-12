{
  config,
  pkgs,
  ...
}: {
  home = {
    file = {
      # ABCL’s init file (https://abcl.org/)
      ".abclrc".source = ./init.lisp;
      # Allegro CL’s init file
      # (https://franz.com/support/documentation/10.1/doc/startup.htm#init-files-1)
      ".clinit.cl".source = ./init.lisp;
      # CLISP’s init file (https://clisp.sourceforge.io/impnotes/clisp.html)
      ".clisprc.lisp".source = ./init.lisp;
      # ECL’s init file
      # (https://ecl.common-lisp.dev/static/manual/Invoking-ECL.html#Invoking-ECL)
      ".ecl".source = ./init.lisp;
      # SBCL’s init file
      # (https://www.sbcl.org/manual/index.html#Initialization-Files)
      ".sbclrc".text = ''
        (load #p"${./init.lisp}")

        (defvar asdf::*source-to-target-mappings* '((#p"/usr/local/lib/sbcl/" nil)))
      '';
      # Clozure CL’s init file
      # (https://ccl.clozure.com/docs/ccl.html#the-init-file)
      "ccl-init.lisp".text = ''
        (setf *default-file-character-encoding* :utf-8)
        (load #p"${./init.lisp}")
      '';
      # CMUCL’s init file
      # (https://cmucl.org/docs/cmu-user/html/Command-Line-Options.html#Command-Line-Options)
      "init.lisp".source = ./init.lisp;
    };

    sessionVariables.LW_INIT = "${pkgs.writeTextFile {
      name = "lispworks-init.lisp";
      text = ''
        #+lispworks  (mp:initialize-multiprocessing)

        (load #p"${./init.lisp}")

        (ql:quickload "swank")
        (swank:create-server :port 4005)
      '';
    }}";
  };
}
