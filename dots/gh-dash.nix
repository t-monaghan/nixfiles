{
  prSections = [
    { title = "My Pull Requests"; filters = "is:open author:@me -org:cultureamp"; layout = { author = { hidden = true; }; }; }
    { title = "Needs My Review"; filters = "is:open review-requested:@me -org:cultureamp"; }
  ];
  issuesSections = [
    { title = "Created"; filters = "is:open author:@me -org:cultureamp"; }
    { title = "Assigned"; filters = "is:open assignee:@me -org:cultureamp"; }
  ];
  defaults = {
    layout = { prs = { repo = { grow = "true,"; width = 10; hidden = false; }; }; };
    prsLimit = 20;
    issuesLimit = 20;
    preview = { open = true; width = 60; };
    refetchIntervalMinutes = 30;
  };
  repoPaths = { ":owner/:repo" = "~/dev/:repo"; };
  pager = { diff = "less"; };
}
