import Foundation

struct ContactCard {
    let firstName: String
    let lastName: String
    let middleName: String
    let title: String
    let organization: String
    let phonePrimary: String
    let phoneBackup: String
    let phoneLandline: String
    let email: String
    let websiteWork: String
    let websitePersonal: String
    let linkedin: String
    let address: String

    var fullName: String {
        "\(firstName) \(middleName) \(lastName)"
    }

    var vCardString: String {
        """
        BEGIN:VCARD
        VERSION:3.0
        N:\(lastName);\(firstName);\(middleName);;
        FN:\(fullName)
        ORG:\(organization)
        TITLE:\(title)
        TEL;TYPE=CELL,VOICE,pref:\(phonePrimary)
        TEL;TYPE=CELL,VOICE:\(phoneBackup)
        TEL;TYPE=WORK,VOICE:\(phoneLandline)
        EMAIL;TYPE=WORK,pref:\(email)
        URL;TYPE=WORK:\(websiteWork)
        URL;TYPE=HOME:\(websitePersonal)
        item1.URL:\(linkedin)
        item1.X-ABLabel:LinkedIn
        ADR;TYPE=WORK:;;\(address)
        NOTE:Digital Business Card | \(organization) | \(websitePersonal)
        END:VCARD
        """
        .split(separator: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .joined(separator: "\r\n")
    }

    var websiteURL: URL {
        URL(string: websitePersonal)!
    }

    static let `default` = ContactCard(
        firstName: "Harshpreet",
        lastName: "Bhasin",
        middleName: "Singh",
        title: "Managing Partner | CEO",
        organization: "HotBot Studios LLP",
        phonePrimary: "+919700001534",
        phoneBackup: "+919479470052",
        phoneLandline: "01141610560",
        email: "Harshpreet@hotbotstudios.com",
        websiteWork: "https://www.hotbotstudios.com",
        websitePersonal: "https://harshpreetbhasin.com",
        linkedin: "https://www.linkedin.com/in/harshpreet-singh-bhasin/",
        address: "2nd Floor\\, M-430 Guruharkishan Nagar;Paschim Vihar;New Delhi;110087;India"
    )
}
