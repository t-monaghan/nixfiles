{
  enable = true;
  config = {
    Label = "com.bobko.aerospace";
    Program = "/usr/bin/open";
    ProgramArguments = [ "-a" "Aerospace" "--started-at-login" ];
    RunAtLoad = true;
  };
}
