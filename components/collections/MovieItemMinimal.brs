' SPDX-FileCopyrightText: 2020 The Jellyfin Project https://github.com/jellyfin
'
' SPDX-License-Identifier: GPL-2.0-or-later

sub Init()
  m.title = m.top.findNode("title")
  m.title.text = tr("Loading...")
end sub

function itemContentChanged() as void
  ' re-declare this because init doesnt re-run
  ' when we come back from elsewhere
  m.title = m.top.findNode("title")

  itemData = m.top.itemContent
  m.title.text = itemData.title
end function
