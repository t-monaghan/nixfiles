set current_url (git remote get-url origin)
set new_url (echo $current_url | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
git remote set-url origin https://github.com/$new_url
