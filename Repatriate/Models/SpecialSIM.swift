import Foundation

/// One of the pre-programmed "SPECIAL SIM CARDS".
///
/// Each physical card is numbered 1...6 and is known to be provisioned with a
/// single, unique MSISDN. The app maps the card number to that MSISDN so the
/// operator never has to type a phone number.
struct SpecialSIM: Identifiable, Hashable {
    /// Card number printed on the SIM (1...6). Doubles as the identity.
    let id: Int

    /// The MSISDN (international format, no leading `+`) assigned to the card.
    let msisdn: String

    /// Human-readable label for lists and headings.
    var title: String { "SIM \(id)" }

    /// The fixed set of special SIMs (at most six).
    ///
    /// TODO: the MSISDNs below are PLACEHOLDERS. Replace each with the real
    /// number provisioned on the corresponding card before field use.
    static let all: [SpecialSIM] = [
        SpecialSIM(id: 1, msisdn: "447770000001"),
        SpecialSIM(id: 2, msisdn: "447770000002"),
        SpecialSIM(id: 3, msisdn: "447770000003"),
        SpecialSIM(id: 4, msisdn: "447770000004"),
        SpecialSIM(id: 5, msisdn: "447770000005"),
        SpecialSIM(id: 6, msisdn: "447770000006")
    ]
}
