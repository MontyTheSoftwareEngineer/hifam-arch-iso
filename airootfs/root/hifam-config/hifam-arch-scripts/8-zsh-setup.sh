#!/bin/sh
echo "Setting up Zsh..."

# Install Oh My Zsh inside zsh
zsh -c '
  RUNZSH=no CHSH=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
'

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

echo "Installing zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Installing zshrc"
rm -f ~/.zshrc
cp ~/OmarchyDotFiles/zshrc ~/.zshrc
cp ~/OmarchyDotFiles/p10k.zsh ~/.p10k.zsh
chsh -s $(which zsh)
cp ~/OmarchyDotFiles/zsh_history ~/.zsh_history
