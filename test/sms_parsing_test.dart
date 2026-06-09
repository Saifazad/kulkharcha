import 'package:flutter_test/flutter_test.dart';
import 'package:kulkharcha/services/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMSService SMS Parsing Unit Tests', () {
    late SMSService smsService;

    setUp(() {
      smsService = SMSService();
    });

    group('isBankSMS Detection', () {
      test('should recognize HDFC Bank debit SMS', () {
        const sms = 'Alert: Your A/c X1234 has been debited with Rs. 1500.00 on 09-06-2026 for shopping.';
        expect(smsService.isBankSMS(sms), isTrue);
      });

      test('should recognize Kotak Bank UPI debit SMS', () {
        const sms = 'Sent Rs.24.00 from XXXXXX5793 to QAYYUM AHMAD on 20/05/2026. Ref: 614050519123';
        expect(smsService.isBankSMS(sms), isTrue);
      });

      test('should recognize SBI ATM withdrawal SMS', () {
        const sms = 'Txn of INR 10,000.00 debited from A/c XX3456 at SBI ATM Patna.';
        expect(smsService.isBankSMS(sms), isTrue);
      });

      test('should reject non-financial messages', () {
        const sms = 'Congratulations! You have won a lottery coupon of Rs 5000. Click here to claim.';
        expect(smsService.isBankSMS(sms), isFalse);
      });

      test('should reject pure credit alert messages (since we only track expenditures/debits)', () {
        const sms = 'Dear Customer, your a/c XX1234 has been credited with INR 25,000.00. Salary credited.';
        expect(smsService.isBankSMS(sms), isFalse);
      });
    });

    group('extractAmount Parsing', () {
      test('should parse "Rs. 1500.00"', () {
        const sms = 'Your A/c X1234 has been debited with Rs. 1500.00 on 09-06-2026.';
        expect(smsService.extractAmount(sms), equals(1500.0));
      });

      test('should parse "Rs.24.00" without spaces', () {
        const sms = 'Sent Rs.24.00 from XXXXXX5793 to QAYYUM AHMAD.';
        expect(smsService.extractAmount(sms), equals(24.0));
      });

      test('should parse "INR 10,000.00" with commas', () {
        const sms = 'Txn of INR 10,000.00 debited from A/c XX3456.';
        expect(smsService.extractAmount(sms), equals(10000.0));
      });

      test('should parse "spent Rs 985.00"', () {
        const sms = 'Rs 985.00 spent at Pizza Hut.';
        expect(smsService.extractAmount(sms), equals(985.0));
      });
    });

    group('autoDetectCategory Categorization', () {
      test('should categorize Mandi/Kisan as Kheti/Farming', () {
        const sms1 = 'Paid Rs. 1200 at Mandi fertilizer store.';
        const sms2 = 'Sent Rs. 500 to Kisan Seva Kendra.';
        expect(smsService.autoDetectCategory(sms1), equals('Kheti/Farming'));
        expect(smsService.autoDetectCategory(sms2), equals('Kheti/Farming'));
      });

      test('should categorize Swiggy/Zomato as Food & Groceries', () {
        const sms = 'Paid Rs. 350.00 to Zomato for food order.';
        expect(smsService.autoDetectCategory(sms), equals('Food & Groceries'));
      });

      test('should categorize Petrol/CNG/Uber as Fuel & Transport', () {
        const sms1 = 'Debited Rs. 500 at HPCL petrol pump.';
        const sms2 = 'Paid Rs. 150 to Uber Cab.';
        expect(smsService.autoDetectCategory(sms1), equals('Fuel & Transport'));
        expect(smsService.autoDetectCategory(sms2), equals('Fuel & Transport'));
      });

      test('should categorize Jio/Recharge as Bills & Recharges', () {
        const sms = 'Debited Rs 299 for Jio recharge bill.';
        expect(smsService.autoDetectCategory(sms), equals('Bills & Recharges'));
      });

      test('should categorize Amazon/Flipkart as Shopping', () {
        const sms = 'Paid Rs. 1499 to Amazon India.';
        expect(smsService.autoDetectCategory(sms), equals('Shopping'));
      });

      test('should categorize Apollo/Hospital as Medical & Health', () {
        const sms = 'Debited Rs. 450 at Apollo Pharmacy.';
        expect(smsService.autoDetectCategory(sms), equals('Medical & Health'));
      });

      test('should categorize ATM cash as Cash (ATM)', () {
        const sms = 'INR 5000 withdrawn from ATM A/c XX2345.';
        expect(smsService.autoDetectCategory(sms), equals('Cash (ATM)'));
      });
    });
  });
}
