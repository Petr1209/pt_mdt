Locales = Locales or {}

function _U(str, ...)
    local lang = Config.Locale or 'cs'
    if not Locales[lang] then lang = 'en' end
    
    local text = Locales[lang] and Locales[lang][str] or (Locales['en'] and Locales['en'][str] or str)
    if ... then
        return string.format(text, ...)
    end
    return text
end

function GetCurrentLocaleTable()
    local lang = Config.Locale or 'cs'
    return Locales[lang] or Locales['en'] or {}
end
