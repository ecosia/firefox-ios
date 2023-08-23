import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        abTest = "ab_Test",
        browser,
        external,
        migration,
        navigation,
        onboarding,
        intro,
        invitations,
        ntp,
        menu,
        menuStatus = "menu_status",
        settings,
        bookmarks
    }
    
    enum Label {
        enum Navigation: String {
            case
            inapp,
            home,
            projects,
            counter,
            financialReports = "financial_reports",
            shop,
            faq,
            news,
            next,
            privacy,
            sendFeedback = "send_feedback",
            skip,
            terms,
            treecard,
            treestore
        }
        
        enum Browser: String {
            case
            favourites,
            history,
            tabs,
            settings,
            newTab = "new_tab",
            blockImages = "block_images",
            searchbar = "searchbar"
        }
        
        enum Bookmarks: String {
            case
            importFunctionality = "import_functionality",
            learnMore = "learn_more",
            bookmarksPromo = "bookmarks_promo",
            `import`
        }
    }
    
    enum Action: String {
        case
        view,
        open,
        receive,
        error,
        completed,
        success,
        retry,
        send,
        claim,
        click,
        change,
        display
        
        enum Activity: String {
            case
            launch,
            resume
        }
        
        enum Browser: String {
            case
            open,
            start,
            complete,
            enable,
            disable
        }

        enum Promo: String {
            case
            view,
            click,
            close
        }
        
        enum Bookmarks: String {
            case
            `import`
        }
    }
    
    enum Property {
        case
        home,
        menu,
        toolbar
        
        var rawValue: String {
            switch self {
            case .home:
                return "home"
            case .menu:
                return "menu"
            case .toolbar:
                return "toolbar"
            }
        }
        
        enum TopSite: String {
            case
            blog,
            privacy,
            financialReports = "financial_reports",
            howEcosiaWorks = "how_ecosia_works"
        }
        
        enum Bookmarks: String {
            case
            `import`,
            export,
            emptyState = "empty_state",
            success,
            error
        }
        
        enum OnboardingPage: String, CaseIterable {
            case
            start,
            search,
            profits,
            action,
            privacy,
            greenSearch = "green_search",
            transparentFinances = "transparent_finances"
        }
    }

    enum Migration: String {
        case
        tabs,
        favourites,
        history,
        exception
    }

    enum ShareContent: String {
        case
        ntp,
        web,
        file
    }
}
