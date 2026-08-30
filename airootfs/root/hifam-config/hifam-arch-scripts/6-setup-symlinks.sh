#!/bin/sh

echo "Set up symlinks for Quattro"

echo "Nvim..."
mv ~/.config/nvim ~/.config/nvim.bak
ln -s ~/OmarchyDotFiles/nvim ~/.config/nvim

echo "Kitty..."
mv ~/.config/kitty ~/.config/kitty.bak
ln -s ~/OmarchyDotFiles/kitty ~/.config/kitty

echo "Tmux"
cp ~/OmarchyDotFiles/tmux.conf ~/.config/tmux/

echo "Waybar"
mv ~/.config/waybar ~/.config/waybar.bak
ln -s ~/OmarchyDotFiles/waybar ~/.config/waybar
