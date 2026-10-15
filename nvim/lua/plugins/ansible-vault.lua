return {
	{
		"fcharlier/neovim-ansible-vault",
		-- Load for YAML, Ansible YAML and vault files
		ft = { "yaml", "yaml.ansible", "ansible-vault" },
		-- In init so the settings exist before the plugin loads
		init = function()
			vim.g.ansible_vault_password_file = "~/.ansible/vault_pass"
			-- or: vim.g.ansible_vault_identity = "default@~/.ansible/vault_pass"
		end,
	},
}
