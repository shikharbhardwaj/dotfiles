require('rose-pine').setup({
    highlight_groups = {
        LineNr = { bg = 'overlay' },
        CursorLine = { bg = 'overlay' },
    }
})

function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd(":colorscheme " .. color)
end

ColorMyPencils()

