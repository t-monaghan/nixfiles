{
  recipe.gh = {
    command = "gh release list --repo joshmedeski/sesh --json name,publishedAt";
    columns = ["name" "publishedAt"];
  };
  page = [
    {
      title = "GitHub";
      sections = [
        {
          title = "Releases";
          recipe = "gh";
        }
      ];
    }
  ];
}
