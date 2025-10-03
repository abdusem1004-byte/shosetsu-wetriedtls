-- WeTriedTLs.lua
-- { "id": 5000001, "ver": "1.0.0", "libVer": "1.0.0", "author": "abdusem1004-byte", "repo": "", "dep": {} }

local WeTried = {}
local base = "https://wetriedtls.com"

-- URL join helper
local function joinUrl(base, path)
    if path:sub(1,1) == "/" then
        return base .. path
    end
    return base .. "/" .. path
end

-- Encode query params
local function urlEncode(str)
    if not str then return "" end
    str = str:gsub("\n", "\r\n")
    str = str:gsub("([^%w _%%%-%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "+")
    return str
end

-- 🔎 Search novels
function WeTried.search(query, page)
    page = page or 1
    local q = urlEncode(query)
    local url = joinUrl(base, "?s=" .. q .. "&paged=" .. page)

    local res = http.get(url)
    if not res or res.code ~= 200 then return nil, false end
    local html = res.body

    local novels = {}
    for entry in html:gmatch('<div%s+class="post%-item.-</div>%s*</div>') do
        local title = entry:match('<h2%s+class="post%-title">%s*<a[^>]+>(.-)</a>')
        local link = entry:match('<h2%s+class="post%-title">%s*<a href="([^"]+)"')
        local thumb = entry:match('<img[^>]+src="([^"]+)"')
        if title and link then
            table.insert(novels, { name = title, url = link, cover = thumb })
        end
    end

    local hasMore = html:find('class="next page%-numbers"') ~= nil
    return novels, hasMore
end

-- 📖 Get novel info
function WeTried.getNovelInfo(novelUrl)
    local res = http.get(novelUrl)
    if not res or res.code ~= 200 then return nil end
    local html = res.body

    local novel = {}
    novel.url = novelUrl
    novel.name = html:match('<h1%s+class="entry%-title">(.-)</h1>')
    novel.cover = html:match('<div%s+class="post%-thumbnail">.-<img[^>]+src="([^"]+)"')
    novel.author = html:match('<span%s+class="author%-name">([^<]+)')
                    or html:match('By%s*<a[^>]+>([^<]+)</a>')
    novel.description = html:match('<div%s+class="entry%-content">(.-)<div%s+class="tags"')
                       or html:match('<div%s+class="entry%-content">(.-)</div>')

    novel.chapters = {}
    -- Chapters usually in list items
    for link, chapname in html:gmatch('<li>%s*<a href="([^"]+)"[^>]*>([^<]+)</a>') do
        table.insert(novel.chapters, { name = chapname, url = link })
    end

    return novel
end

-- 📄 Get chapter content
function WeTried.getChapter(chapterUrl)
    local res = http.get(chapterUrl)
    if not res or res.code ~= 200 then return nil end
    local html = res.body

    local title = html:match('<h1%s+class="entry%-title">(.-)</h1>')
    local body = html:match('<div%s+class="entry%-content">(.-)<div%s+class="tags"')
                 or html:match('<div%s+class="entry%-content">(.-)</div>')

    if body then body = cleanContent(body) end

    return { title = title, body = body }
end

-- 🧹 Clean HTML content
function cleanContent(html)
    html = html:gsub("<script.->.-</script>", "")
    html = html:gsub("<!--.-?-->", "")
    html = html:gsub('<div%s+class="ad">.-</div>', "")
    return html
end

return WeTried
