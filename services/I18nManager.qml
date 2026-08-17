pragma Singleton

import QtQuick

// I18n Manager Service
// Handles internationalization and multi-language support

QtObject {
    id: root
    
    // Available languages
    property list<string> availableLanguages: ["en", "id", "ja", "zh_CN", "fr", "es", "de", "pt_BR"]
    property string currentLanguage: "en"
    
    // Language names
    property var languageNames: {
        "en": "English",
        "id": "Bahasa Indonesia",
        "ja": "日本語",
        "zh_CN": "中文 (简体)",
        "fr": "Français",
        "es": "Español",
        "de": "Deutsch",
        "pt_BR": "Português (Brasil)"
    }
    
    // RTL languages
    property list<string> rtlLanguages: ["ar", "he", "fa", "ur"]
    
    // Strings (translation dictionary)
    property var strings: {
        "en": {
            "menu": "Menu",
            "settings": "Settings",
            "theme": "Theme",
            "battery": "Battery",
            "volume": "Volume",
            "brightness": "Brightness",
            "wifi": "WiFi",
            "bluetooth": "Bluetooth",
            "about": "About",
            "exit": "Exit"
        },
        "id": {
            "menu": "Menu",
            "settings": "Pengaturan",
            "theme": "Tema",
            "battery": "Baterai",
            "volume": "Volume",
            "brightness": "Kecerahan",
            "wifi": "WiFi",
            "bluetooth": "Bluetooth",
            "about": "Tentang",
            "exit": "Keluar"
        },
        "ja": {
            "menu": "メニュー",
            "settings": "設定",
            "theme": "テーマ",
            "battery": "バッテリー",
            "volume": "音量",
            "brightness": "明るさ",
            "wifi": "WiFi",
            "bluetooth": "Bluetooth",
            "about": "について",
            "exit": "終了"
        }
    }
    
    // Methods
    function setLanguage(langCode) {
        if (!root.availableLanguages.includes(langCode)) {
            console.warn(`[I18nManager] Language not available: ${langCode}`)
            return false
        }
        
        root.currentLanguage = langCode
        console.log(`[I18nManager] Language changed to: ${root.languageNames[langCode]}`)
        return true
    }
    
    function getString(key, lang) {
        const language = lang ?? root.currentLanguage
        const translation = root.strings[language] ?? root.strings["en"]
        return translation[key] ?? key
    }
    
    function isRTL() {
        return root.rtlLanguages.includes(root.currentLanguage)
    }
    
    function getLanguageList() {
        return root.availableLanguages.map(lang => ({
            code: lang,
            name: root.languageNames[lang]
        }))
    }
    
    function addTranslation(langCode, key, value) {
        if (!root.strings[langCode]) {
            root.strings[langCode] = {}
        }
        root.strings[langCode][key] = value
        console.log(`[I18nManager] Added translation: ${langCode}.${key}`)
    }
    
    function getDebugInfo() {
        return {
            current: root.currentLanguage,
            available: root.availableLanguages,
            rtl: root.isRTL()
        }
    }
    
    Component.onCompleted: {
        console.log(`[I18nManager] I18n manager initialized (${root.currentLanguage})`)
    }
}
