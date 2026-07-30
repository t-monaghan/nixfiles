# `flakePath` + `homeConfigName` arrive via `_module.args` (see ./default.nix).
# On the Macs they point nixd at this flake; on the NixOS box they are null
# and nixd falls back to the channel-based `<nixpkgs>` expressions.
{
  flakePath,
  homeConfigName,
  ...
}: {
  plugins.lsp = {
    enable = true;

    servers = {
      gopls.enable = true;
      golangci_lint_ls.enable = true;
      # Kept for its fast dead-code / lint diagnostics (unused bindings, no-op
      # patterns). nixd owns completion + hover (see below).
      nil_ls.enable = true;
      nixd = {
        enable = true;
        # These settings are what unlock nixd's best features. Without them it
        # falls back to generic AST completion (~nil-tier).
        # Formatting is handled by conform (alejandra), so nixd formatting is
        # intentionally left unset in both branches.
        settings =
          if flakePath != null
          then {
            # `builtins.getFlake "${flakePath}"` resolves this flake's store
            # source (self.outPath) — stable and identical on every host, so no
            # path or username guessing. Reflects the option schema as of the
            # last rebuild.
            # Package-name completion + eval-based hover from this flake's nixpkgs.
            nixpkgs.expr = ''import (builtins.getFlake "${flakePath}").inputs.nixpkgs { }'';
            # Option-aware completion + hover docs for this host's home-manager
            # options (home.*, programs.*, services.*, ...).
            options.home-manager.expr = ''(builtins.getFlake "${flakePath}").homeConfigurations.${homeConfigName}.options'';
          }
          else {
            # Non-flake: nixd resolves nixpkgs + NixOS options via the channel
            # (<nixpkgs> comes from NIX_PATH, which channel-based nixos-rebuild sets).
            nixpkgs.expr = "import <nixpkgs> { }";
            options.nixos.expr = "(import <nixpkgs/nixos> { configuration = { }; }).options";
          };
      };
      taplo.enable = true;
      ty.enable = true;
      jsonls.enable = true;
      ruff.enable = true;
      yamlls.enable = true;
      terraformls.enable = true;
      tflint.enable = true;
      eslint.enable = true;
      ts_ls.enable = true;
      bashls.enable = true;
      lua_ls = {
        enable = true;
        settings.Lua.completion.callSnippet = "Replace";
      };
    };

    onAttach = ''
      local map = function(keys, func, desc, mode)
        mode = mode or "n"
        vim.keymap.set(mode, keys, func, {buffer = bufnr, desc = "LSP: " .. desc})
      end

      map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
      map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", {"n", "x"})
      map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
      map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
      map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
      map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
      map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
      map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

      -- Highlight references on CursorHold
      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
        local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", {clear = false})
        vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
          buffer = bufnr,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
          buffer = bufnr,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd("LspDetach", {
          group = vim.api.nvim_create_augroup("kickstart-lsp-detach", {clear = true}),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds({group = "kickstart-lsp-highlight", buffer = event2.buf})
          end,
        })
      end

      -- Toggle inlay hints
      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr) then
        map("<leader>th", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr = bufnr}))
        end, "[T]oggle Inlay [H]ints")
      end
    '';
  };
}
