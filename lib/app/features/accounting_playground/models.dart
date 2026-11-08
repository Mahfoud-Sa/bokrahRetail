/// Exact minor-unit amounts. Parsing rejects excess precision instead of rounding.
class Money {
  const Money(this.minor, {this.precision = 2, this.currency = 'JOD'})
    : assert(precision >= 0 && precision <= 6),
      assert(minor >= -9007199254740991 && minor <= 9007199254740991);
  final int minor, precision;
  final String currency;
  static Money parse(
    String input, {
    int precision = 2,
    String currency = 'JOD',
  }) {
    var s = input.trim();
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    }
    s = s.replaceAll('٫', '.');
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) {
      throw const FormatException('Invalid amount');
    }
    final parts = s.replaceAll('-', '').split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > precision) {
      throw const FormatException('Excess precision');
    }
    final scale = _scale(precision);
    // Bound before int parsing so Flutter web cannot lose integer precision.
    final absolute =
        BigInt.parse(parts[0]) * BigInt.from(scale) +
        (precision == 0
            ? BigInt.zero
            : BigInt.parse(fraction.padRight(precision, '0')));
    if (absolute > BigInt.from(9007199254740991)) {
      throw const FormatException('Amount exceeds safe minor-unit range');
    }
    final value =
        int.parse(parts[0]) * scale +
        (precision == 0 ? 0 : int.parse(fraction.padRight(precision, '0')));
    return Money(
      s.startsWith('-') ? -value : value,
      precision: precision,
      currency: currency,
    );
  }

  static int _scale(int precision) {
    if (precision < 0 || precision > 6) {
      throw ArgumentError('Precision 0–6 required');
    }
    return [1, 10, 100, 1000, 10000, 100000, 1000000][precision];
  }

  Money operator +(Money other) {
    _compatible(other);
    return _checked(BigInt.from(minor) + BigInt.from(other.minor));
  }

  Money operator -(Money other) {
    _compatible(other);
    return _checked(BigInt.from(minor) - BigInt.from(other.minor));
  }

  Money _checked(BigInt value) {
    if (value.abs() > BigInt.from(9007199254740991)) {
      throw const FormatException('Amount exceeds safe minor-unit range');
    }
    return Money(value.toInt(), precision: precision, currency: currency);
  }

  void _compatible(Money other) {
    if (precision != other.precision || currency != other.currency) {
      throw ArgumentError('Incompatible currency/precision');
    }
  }

  String format({
    bool arabic = false,
    bool symbol = false,
    bool dashZero = false,
    bool parentheses = true,
  }) {
    if (dashZero && minor == 0) return '—';
    final scale = _scale(precision), absolute = minor.abs();
    var whole = '${absolute ~/ scale}'.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => arabic ? '٬' : ',',
    );
    if (precision > 0) {
      whole +=
          '${arabic ? '٫' : '.'}${(absolute % scale).toString().padLeft(precision, '0')}';
    }
    if (arabic) {
      whole = whole
          .split('')
          .map((c) => int.tryParse(c) == null ? c : '٠١٢٣٤٥٦٧٨٩'[int.parse(c)])
          .join();
    }
    final unit = symbol && currency == 'JOD'
        ? (arabic ? 'د.أ' : 'JD')
        : currency;
    final value = '$whole $unit';
    return minor < 0 ? (parentheses ? '($value)' : '−$value') : value;
  }
}

class Company {
  const Company(this.id, this.name, this.arabicName);
  final String id, name, arabicName;
}

class FiscalPeriod {
  const FiscalPeriod(this.id, this.start, this.end);
  final String id;
  final DateTime start, end;
}

class Account {
  const Account(
    this.code,
    this.name,
    this.arabicName,
    this.type,
    this.balance, {
    this.parent,
    this.active = true,
  });
  final String code, name, arabicName, type;
  final Money balance;
  final String? parent;
  final bool active;
}

class JournalEntryLine {
  JournalEntryLine({
    this.account = '1001',
    this.debit = '0.00',
    this.credit = '0.00',
  });
  String account, debit, credit;
}

class JournalEntry {
  JournalEntry({
    required this.reference,
    required this.date,
    required this.period,
    this.description = '',
    required this.lines,
  });
  final String reference, period;
  final DateTime date;
  String description;
  final List<JournalEntryLine> lines;
}

class Transaction {
  const Transaction(
    this.id,
    this.date,
    this.description,
    this.arabicDescription,
    this.type,
    this.status,
    this.amount,
  );
  final String id, description, arabicDescription, type, status;
  final DateTime date;
  final Money amount;
  Transaction withStatus(String value) => Transaction(
    id,
    date,
    description,
    arabicDescription,
    type,
    value,
    amount,
  );
}

class InvoiceLine {
  const InvoiceLine(this.name, this.arabicName, this.quantity, this.unitPrice);
  final String name, arabicName;
  final int quantity;
  final Money unitPrice;
  Money get total => Money(quantity * unitPrice.minor);
}

class Invoice {
  const Invoice(
    this.id,
    this.party,
    this.arabicParty,
    this.lines, {
    this.discount = const Money(0),
    this.taxBasisPoints = 1000,
    this.paid = const Money(0),
  });
  final String id, party, arabicParty;
  final List<InvoiceLine> lines;
  final Money discount, paid;
  final int taxBasisPoints;
  Money get subtotal => lines.fold(const Money(0), (a, b) => a + b.total);
  Money get tax {
    final numerator = (subtotal.minor - discount.minor) * taxBasisPoints;
    if (numerator % 10000 != 0) {
      throw StateError('Explicit tax rounding policy required');
    }
    return Money(numerator ~/ 10000);
  }

  Money get total => subtotal - discount + tax;
  Money get due => total - paid;
  String get status => due.minor == 0
      ? 'paid'
      : paid.minor > 0
      ? 'partial'
      : 'pending';
}

class ReportRow {
  const ReportRow(
    this.group,
    this.label,
    this.arabicLabel,
    this.current,
    this.comparison,
  );
  final String group, label, arabicLabel;
  final Money current, comparison;
}

class FinancialReport {
  const FinancialReport(this.name, this.arabicName, this.rows);
  final String name, arabicName;
  final List<ReportRow> rows;
}
