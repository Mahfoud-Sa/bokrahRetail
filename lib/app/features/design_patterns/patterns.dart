import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'pattern_models.dart';

enum PatternKind {
  authentication,
  crud,
  search,
  forms,
  lists,
  dashboard,
  notifications,
  errors,
  permissions,
}

String patternTitle(PatternKind kind, bool ar) => (ar
    ? const [
        'المصادقة',
        'إدارة السجلات',
        'البحث والتصفية',
        'النماذج',
        'القوائم',
        'لوحة المعلومات',
        'الإشعارات',
        'معالجة الأخطاء',
        'الصلاحيات',
      ]
    : const [
        'Authentication',
        'CRUD',
        'Search & Filtering',
        'Forms',
        'Lists',
        'Dashboard',
        'Notifications',
        'Error Handling',
        'Permissions',
      ])[kind.index];

class PatternsCatalogue extends StatelessWidget {
  const PatternsCatalogue({super.key, required this.arabic});
  final bool arabic;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      BkSectionHeader(
        title: arabic ? '٧. أنماط التصميم' : '7. Design Patterns',
        description: arabic
            ? 'تجارب كاملة ببيانات محلية تجريبية. لا تتصل بخدمات فعلية.'
            : 'Complete flows with local sample data. No live services are connected.',
      ),
      for (final kind in PatternKind.values)
        BkCard(
          child: BkSectionHeader(
            title: patternTitle(kind, arabic),
            action: BkButton(
              label:
                  '${arabic ? 'افتح النمط: ' : 'Open pattern: '}${patternTitle(kind, arabic)}',
              variant: BkButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PatternDemo(kind: kind, arabic: arabic),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// A recipe, not a production service or authorization boundary.
class PatternDemo extends StatefulWidget {
  const PatternDemo({super.key, required this.kind, required this.arabic});
  final PatternKind kind;
  final bool arabic;
  @override
  State<PatternDemo> createState() => _PatternDemoState();
}

class _PatternDemoState extends State<PatternDemo> {
  final name = TextEditingController(),
      amount = TextEditingController(),
      query = TextEditingController(),
      email = TextEditingController(text: 'demo@bokrah.example'),
      password = TextEditingController(text: 'demo123'),
      otp = TextEditingController(text: '000000'),
      authName = TextEditingController(text: 'Demo'),
      draft = TextEditingController(text: 'Unsaved sample / مسودة تجريبية');
  final scroll = ScrollController();
  List<DemoRecord> records = demoRecords();
  final notes = <({int id, bool read})>[
    (id: 1, read: false),
    (id: 2, read: false),
  ];
  int nextId = 6, step = 0, page = 1, visible = 3, refreshes = 0, nextNote = 3;
  int? editId;
  String role = 'owner',
      category = 'all',
      authMode = 'login',
      errorCode = '401',
      message = '';
  bool busy = false,
      sortAmount = false,
      infinite = false,
      confirmed = false,
      recovered = false;
  String? error;
  String t(String en, String ar) => widget.arabic ? ar : en;
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (widget.kind == PatternKind.lists &&
          infinite &&
          scroll.hasClients &&
          scroll.position.extentAfter < 120) {
        loadMore();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      amount,
      query,
      email,
      password,
      otp,
      authName,
      draft,
    ]) {
      controller.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Future<void> simulate(VoidCallback complete) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = t('Processing sample…', 'جارٍ معالجة المثال…');
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      busy = false;
      complete();
    });
  }

  Widget feedback() => Semantics(liveRegion: true, child: Text(message));
  Widget choice(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label),
      DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: [
          for (final item in options)
            DropdownMenuItem(value: item.$1, child: Text(item.$2)),
        ],
        onChanged: busy
            ? null
            : (value) {
                if (value != null) change(value);
              },
      ),
    ],
  );
  Widget actions(List<Widget> children) => BkRow(children: children);
  Widget roleChoice() => choice(
    t('Preview role', 'الدور التجريبي'),
    role,
    [
      ('owner', t('Owner', 'المالك')),
      ('cashier', t('Cashier', 'أمين الصندوق')),
      ('viewer', t('Viewer', 'مشاهد')),
    ],
    (value) => setState(() {
      role = value;
      message = '';
    }),
  );
  @override
  Widget build(BuildContext context) => BkPageScaffold(
    appBar: AppBar(title: Text(patternTitle(widget.kind, widget.arabic))),
    body: widget.kind == PatternKind.lists
        ? listPattern()
        : SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(BkSpace.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: BkColumn(
                  children: [
                    Text(
                      t(
                        'Local sample only. No account, message or production record is created.',
                        'مثال محلي فقط. لا يُنشأ حساب أو رسالة أو سجل فعلي.',
                      ),
                    ),
                    switch (widget.kind) {
                      PatternKind.authentication => authentication(),
                      PatternKind.crud => crud(),
                      PatternKind.search => search(),
                      PatternKind.forms => formPattern(),
                      PatternKind.dashboard => dashboard(),
                      PatternKind.notifications => notifications(),
                      PatternKind.errors => errors(),
                      PatternKind.permissions => permissions(),
                      PatternKind.lists => const SizedBox.shrink(),
                    },
                  ],
                ),
              ),
            ),
          ),
  );

  Widget authentication() => BkColumn(
    children: [
      choice(
        t('Authentication flow', 'مسار المصادقة'),
        authMode,
        [
          ('login', t('Login', 'دخول')),
          ('register', t('Register', 'حساب جديد')),
          ('forgot', t('Forgot Password', 'نسيت كلمة المرور')),
          ('otp', t('OTP', 'رمز التحقق')),
        ],
        (value) => setState(() {
          authMode = value;
          error = null;
          message = '';
        }),
      ),
      if (authMode == 'register')
        BkTextField(
          label: t('Sample name', 'الاسم التجريبي'),
          controller: authName,
        ),
      if (authMode == 'otp') ...[
        Text(t('Sample code: 000000', 'الرمز التجريبي: 000000')),
        BkTextField(
          label: t('Sample six-digit code', 'الرمز التجريبي من ستة أرقام'),
          controller: otp,
          keyboardType: TextInputType.number,
          errorText: error,
        ),
      ] else ...[
        BkTextField(
          label: t('Sample email', 'البريد التجريبي'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
          errorText: error,
        ),
        if (authMode != 'forgot')
          TextField(
            controller: password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: t('Sample password', 'كلمة المرور التجريبية'),
            ),
          ),
      ],
      BkButton(
        label: t('Continue preview', 'متابعة المعاينة'),
        loading: busy,
        loadingLabel: t('Processing sample', 'جارٍ معالجة المثال'),
        onPressed: () {
          final valid = authMode == 'otp'
              ? otp.text == '000000'
              : RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email.text.trim()) &&
                    (authMode == 'forgot' || password.text.length >= 6) &&
                    (authMode != 'register' || authName.text.trim().isNotEmpty);
          if (!valid) {
            setState(() {
              error = authMode == 'otp'
                  ? t(
                      'Use the sample code 000000.',
                      'استخدم الرمز التجريبي 000000.',
                    )
                  : t(
                      'Enter a sample email, name if required, and password of at least six characters.',
                      'أدخل بريداً تجريبياً والاسم عند الحاجة وكلمة مرور من ستة أحرف على الأقل.',
                    );
            });
            return;
          }
          setState(() => error = null);
          simulate(
            () => message = authMode == 'forgot'
                ? t(
                    'Show the same recovery acknowledgement for every email. No email sent.',
                    'اعرض تأكيد الاستعادة نفسه لأي بريد. لم تُرسل رسالة.',
                  )
                : t(
                    'Preview complete. No real session was created.',
                    'اكتملت المعاينة. لم تُنشأ جلسة فعلية.',
                  ),
          );
        },
      ),
      feedback(),
    ],
  );

  Widget crud() => BkColumn(
    children: [
      roleChoice(),
      BkTextField(
        label: t('Record name', 'اسم السجل'),
        controller: name,
        enabled: canPerform(role, editId == null ? 'create' : 'update'),
      ),
      BkTextField(
        label: t('Sample amount (JOD)', 'المبلغ التجريبي (دينار)'),
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        errorText: error,
        enabled: canPerform(role, editId == null ? 'create' : 'update'),
      ),
      BkButton(
        label: editId == null
            ? t('Create sample record', 'إنشاء سجل تجريبي')
            : t('Save sample changes', 'حفظ التعديلات التجريبية'),
        onPressed: !canPerform(role, editId == null ? 'create' : 'update')
            ? null
            : () {
                if (!canPerform(role, editId == null ? 'create' : 'update')) {
                  return;
                }
                if (!validDraft(name.text, amount.text)) {
                  setState(
                    () => error = t(
                      'Enter a name and positive amount.',
                      'أدخل اسماً ومبلغاً موجباً.',
                    ),
                  );
                  return;
                }
                setState(() {
                  final previous = records
                      .where((r) => r.id == editId)
                      .firstOrNull;
                  final record = DemoRecord(
                    editId ?? nextId++,
                    name.text.trim(),
                    double.parse(amount.text),
                    previous?.category ?? 'sales',
                  );
                  records = editId == null
                      ? [...records, record]
                      : records
                            .map((row) => row.id == editId ? record : row)
                            .toList();
                  editId = null;
                  name.clear();
                  amount.clear();
                  error = null;
                  message = t(
                    'Sample record saved locally.',
                    'حُفظ السجل التجريبي محلياً.',
                  );
                });
              },
      ),
      if (editId != null)
        BkButton(
          label: t('Cancel editing', 'إلغاء التعديل'),
          variant: BkButtonVariant.secondary,
          onPressed: () => setState(() {
            editId = null;
            name.clear();
            amount.clear();
            error = null;
          }),
        ),
      feedback(),
      for (final record in records)
        BkCard(
          child: BkColumn(
            children: [
              Text(record.name),
              Text('${record.amount.toStringAsFixed(2)} JOD'),
              actions([
                BkButton(
                  label: '${t('Read', 'عرض')} #${record.id}',
                  variant: BkButtonVariant.secondary,
                  onPressed: () => showBkModal<void>(
                    context: context,
                    title: t('Sample record details', 'تفاصيل السجل التجريبي'),
                    closeLabel: t('Close details', 'إغلاق التفاصيل'),
                    builder: (_) => Text(
                      '#${record.id} · ${record.name} · ${record.amount.toStringAsFixed(2)} JOD',
                    ),
                  ),
                ),
                BkButton(
                  label: '${t('Update', 'تعديل')} #${record.id}',
                  variant: BkButtonVariant.secondary,
                  onPressed: !canPerform(role, 'update')
                      ? null
                      : () {
                          if (!canPerform(role, 'update')) return;
                          setState(() {
                            editId = record.id;
                            name.text = record.name;
                            amount.text = record.amount.toString();
                            error = null;
                          });
                          scroll.animateTo(
                            0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        },
                ),
                BkButton(
                  label: '${t('Delete', 'حذف')} #${record.id}',
                  variant: BkButtonVariant.danger,
                  onPressed: !canPerform(role, 'delete')
                      ? null
                      : () async {
                          if (!canPerform(role, 'delete')) return;
                          final approved = await showBkModal<bool>(
                            context: context,
                            title: t(
                              'Delete sample record?',
                              'حذف السجل التجريبي؟',
                            ),
                            closeLabel: t('Keep record', 'الاحتفاظ بالسجل'),
                            builder: (dialogContext) => BkColumn(
                              children: [
                                Text(record.name),
                                BkButton(
                                  label: t(
                                    'Confirm sample deletion',
                                    'تأكيد حذف المثال',
                                  ),
                                  variant: BkButtonVariant.danger,
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                          );
                          if (approved != true ||
                              !mounted ||
                              !canPerform(role, 'delete')) {
                            return;
                          }
                          setState(() {
                            records = records
                                .where((row) => row.id != record.id)
                                .toList();
                            if (editId == record.id) {
                              editId = null;
                              name.clear();
                              amount.clear();
                            }
                            message = t(
                              'Sample record deleted.',
                              'حُذف السجل التجريبي.',
                            );
                          });
                        },
                ),
              ]),
            ],
          ),
        ),
      if (records.isEmpty)
        Text(
          t(
            'No sample records. Create one above.',
            'لا توجد سجلات تجريبية. أنشئ سجلاً أعلاه.',
          ),
        ),
      if (!canPerform(role, 'delete'))
        Text(t('Delete requires the Owner role.', 'الحذف يتطلب دور المالك.')),
    ],
  );

  Widget search() {
    final matches = queryRecords(
      records,
      query: query.text,
      category: category,
      sortAmount: sortAmount,
    );
    final pages = ((matches.length + 2) ~/ 3).clamp(1, 1000000);
    page = page.clamp(1, pages);
    return BkColumn(
      children: [
        BkTextField(
          label: t('Search sample records', 'البحث في السجلات التجريبية'),
          controller: query,
          onChanged: (_) => setState(() => page = 1),
        ),
        choice(
          t('Category filter', 'تصفية الفئة'),
          category,
          [
            ('all', t('All', 'الكل')),
            ('sales', t('Sales', 'المبيعات')),
            ('expenses', t('Expenses', 'المصروفات')),
          ],
          (value) => setState(() {
            category = value;
            page = 1;
          }),
        ),
        choice(
          t('Sort records', 'ترتيب السجلات'),
          sortAmount ? 'amount' : 'name',
          [
            ('name', t('Name', 'الاسم')),
            ('amount', t('Amount: low to high', 'المبلغ: من الأقل للأعلى')),
          ],
          (value) => setState(() => sortAmount = value == 'amount'),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            '${matches.length} ${t('matching records', 'سجلات مطابقة')}',
          ),
        ),
        for (final record in matches.skip((page - 1) * 3).take(3))
          BkCard(
            child: Text(
              '${record.name} · ${record.amount.toStringAsFixed(2)} JOD',
            ),
          ),
        if (matches.isEmpty)
          Text(
            t(
              'No results. Clear the search or change filters.',
              'لا توجد نتائج. امسح البحث أو غيّر التصفية.',
            ),
          ),
        actions([
          BkButton(
            label: t('Previous results', 'النتائج السابقة'),
            onPressed: page == 1 ? null : () => setState(() => page--),
          ),
          Text('$page / $pages'),
          BkButton(
            label: t('Next results', 'النتائج التالية'),
            onPressed: page == pages ? null : () => setState(() => page++),
          ),
        ]),
        BkButton(
          label: t('Reset search', 'إعادة ضبط البحث'),
          variant: BkButtonVariant.secondary,
          onPressed: () => setState(() {
            query.clear();
            category = 'all';
            sortAmount = false;
            page = 1;
          }),
        ),
      ],
    );
  }

  Widget formPattern() => BkColumn(
    children: [
      Text('${t('Step', 'الخطوة')} ${step + 1} / 3'),
      if (confirmed) ...[
        Text(
          t(
            'Confirmed locally. No production record was saved.',
            'تم التأكيد محلياً. لم يُحفظ سجل فعلي.',
          ),
        ),
        BkButton(
          label: t('Start another form', 'بدء نموذج آخر'),
          onPressed: () => setState(() {
            confirmed = false;
            step = 0;
            name.clear();
            amount.clear();
          }),
        ),
      ] else if (step == 0) ...[
        BkTextField(
          label: t('Sample entry name', 'اسم القيد التجريبي'),
          controller: name,
        ),
        BkTextField(
          label: t('Sample entry amount', 'مبلغ القيد التجريبي'),
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: error,
        ),
        BkButton(
          label: t('Review form', 'مراجعة النموذج'),
          onPressed: () {
            if (!validDraft(name.text, amount.text)) {
              setState(
                () => error = t(
                  'A name and positive amount are required.',
                  'الاسم والمبلغ الموجب مطلوبان.',
                ),
              );
              return;
            }
            setState(() {
              error = null;
              step = 1;
            });
          },
        ),
      ] else ...[
        Text(
          '${name.text} · ${double.parse(amount.text).toStringAsFixed(2)} JOD',
        ),
        BkButton(
          label: t('Back to previous step', 'الرجوع للخطوة السابقة'),
          variant: BkButtonVariant.secondary,
          onPressed: () => setState(() => step--),
        ),
        BkButton(
          label: step == 1
              ? t('Continue to confirmation', 'متابعة التأكيد')
              : t('Confirm sample form', 'تأكيد النموذج التجريبي'),
          onPressed: () => setState(() {
            if (step == 1) {
              step = 2;
            } else {
              confirmed = true;
            }
          }),
        ),
      ],
    ],
  );

  Future<void> loadMore() async {
    if (busy || !infinite || visible >= 12) return;
    await simulate(() {
      visible = (visible + 3).clamp(0, 12);
      message = t('More sample entries loaded.', 'حُمّلت قيود تجريبية أخرى.');
    });
  }

  Future<void> refreshList() async {
    if (busy) return;
    await simulate(() {
      refreshes++;
      page = 1;
      visible = 3;
      message = t('Sample list refreshed.', 'حُدّثت القائمة التجريبية.');
    });
  }

  Widget listPattern() => RefreshIndicator(
    onRefresh: refreshList,
    child: ListView(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(BkSpace.xl),
      children: [
        BkSectionHeader(
          title: t('List loading recipes', 'أنماط تحميل القائمة'),
          description: t(
            'Pull down to refresh. Buttons also support keyboard users.',
            'اسحب للأسفل للتحديث. تدعم الأزرار مستخدمي لوحة المفاتيح أيضاً.',
          ),
        ),
        choice(
          t('List loading mode', 'طريقة تحميل القائمة'),
          infinite ? 'infinite' : 'pagination',
          [
            ('pagination', t('Pagination', 'ترقيم الصفحات')),
            ('infinite', t('Infinite scroll', 'تمرير مستمر')),
          ],
          (value) {
            setState(() {
              infinite = value == 'infinite';
              page = 1;
              visible = 3;
            });
            if (infinite) loadMore();
          },
        ),
        feedback(),
        for (final i
            in infinite
                ? List.generate(visible, (i) => i + 1)
                : List.generate(3, (i) => (page - 1) * 3 + i + 1))
          Padding(
            padding: const EdgeInsets.only(bottom: BkSpace.lg),
            child: BkCard(
              child: Text(
                '${t('Sample entry', 'قيد تجريبي')} $i · ${t('refresh', 'تحديث')} $refreshes',
              ),
            ),
          ),
        if (busy)
          BkProgress(
            label: t('Loading sample list', 'جارٍ تحميل القائمة التجريبية'),
          ),
        if (infinite)
          BkButton(
            label: t('Load more entries', 'تحميل قيود أخرى'),
            onPressed: busy || visible >= 12 ? null : loadMore,
          )
        else
          actions([
            BkButton(
              label: t('Previous list page', 'صفحة القائمة السابقة'),
              onPressed: busy || page == 1
                  ? null
                  : () => setState(() => page--),
            ),
            Text('$page / 4'),
            BkButton(
              label: t('Next list page', 'صفحة القائمة التالية'),
              onPressed: busy || page == 4
                  ? null
                  : () => setState(() => page++),
            ),
          ]),
        BkButton(
          label: t('Refresh sample list', 'تحديث القائمة التجريبية'),
          onPressed: busy ? null : refreshList,
        ),
        if (infinite && visible == 12)
          Text(t('End of sample list', 'نهاية القائمة التجريبية')),
      ],
    ),
  );

  Widget dashboard() => BkColumn(
    children: [
      for (final entry in [
        (
          t('Sample sales', 'المبيعات التجريبية'),
          records
              .where((r) => r.category == 'sales')
              .fold(0.0, (sum, r) => sum + r.amount),
        ),
        (
          t('Sample expenses', 'المصروفات التجريبية'),
          records
              .where((r) => r.category == 'expenses')
              .fold(0.0, (sum, r) => sum + r.amount),
        ),
        (
          t('Sample balance', 'الرصيد التجريبي'),
          records.fold(
            0.0,
            (sum, r) => sum + (r.category == 'sales' ? r.amount : -r.amount),
          ),
        ),
      ])
        BkStatCard(
          label: entry.$1,
          value: entry.$2.toStringAsFixed(2),
          detail: t('JOD · illustrative', 'دينار · توضيحي'),
        ),
      BkBarChart(
        label: t('Illustrative order counts', 'أعداد طلبات توضيحية'),
        emptyLabel: t('No data', 'لا توجد بيانات'),
        values: [
          BkChartValue(
            label: t('Morning', 'الصباح'),
            value: 40,
            displayValue: '40',
          ),
          BkChartValue(
            label: t('Lunch', 'الغداء'),
            value: 80,
            displayValue: '80',
          ),
          BkChartValue(
            label: t('Evening', 'المساء'),
            value: 60,
            displayValue: '60',
          ),
        ],
      ),
      BkSectionHeader(
        title: t('Recent sample activity', 'آخر النشاطات التجريبية'),
      ),
      BkTimeline(
        entries: [
          BkTimelineEntry(
            title: t('Shift opened', 'بداية الوردية'),
            detail: t('Sample activity', 'نشاط تجريبي'),
            time: '09:00',
          ),
          BkTimelineEntry(
            title: t('Lunch reviewed', 'مراجعة الغداء'),
            detail: t('Sample activity', 'نشاط تجريبي'),
            time: '12:30',
          ),
        ],
      ),
    ],
  );

  Widget notifications() => BkColumn(
    children: [
      BkAlert(
        title: t('Sample import ready', 'الاستيراد التجريبي جاهز'),
        message: t(
          'Review sample records before confirmation.',
          'راجع السجلات التجريبية قبل التأكيد.',
        ),
      ),
      Semantics(
        liveRegion: true,
        child: Text(
          '${notes.where((note) => !note.read).length} ${t('unread notifications', 'إشعارات غير مقروءة')}',
        ),
      ),
      actions([
        BkButton(
          label: t('Mark all as read', 'تحديد الكل كمقروء'),
          onPressed: notes.every((note) => note.read)
              ? null
              : () => setState(() {
                  for (var i = 0; i < notes.length; i++) {
                    notes[i] = (id: notes[i].id, read: true);
                  }
                }),
        ),
        BkButton(
          label: t('Add sample notification', 'إضافة إشعار تجريبي'),
          onPressed: () =>
              setState(() => notes.insert(0, (id: nextNote++, read: false))),
        ),
      ]),
      for (final note in notes)
        BkCard(
          child: BkColumn(
            children: [
              Text('${t('Sample notification', 'إشعار تجريبي')} ${note.id}'),
              Text(note.read ? t('Read', 'مقروء') : t('Unread', 'غير مقروء')),
              BkButton(
                label: '${t('Mark read', 'تحديد كمقروء')} #${note.id}',
                onPressed: note.read
                    ? null
                    : () => setState(() {
                        final index = notes.indexWhere(
                          (value) => value.id == note.id,
                        );
                        notes[index] = (id: note.id, read: true);
                      }),
              ),
            ],
          ),
        ),
    ],
  );

  Widget errors() => BkColumn(
    children: [
      choice(
        t('Preview error', 'معاينة الخطأ'),
        errorCode,
        [
          for (final code in ['401', '403', '404', '500', 'network'])
            (
              code,
              code == 'network' ? t('Network failure', 'فشل الاتصال') : code,
            ),
        ],
        (value) => setState(() {
          errorCode = value;
          message = '';
          recovered = false;
        }),
      ),
      BkTextField(
        label: t('Preserved sample draft', 'المسودة التجريبية المحفوظة'),
        controller: draft,
      ),
      BkAlert(
        title: recovered
            ? t('Sample request recovered', 'نجح الطلب التجريبي')
            : switch (errorCode) {
                '401' => t('Sign-in required', 'تسجيل الدخول مطلوب'),
                '403' => t('Access denied', 'الوصول مرفوض'),
                '404' => t('Page not found', 'الصفحة غير موجودة'),
                '500' => t('Something went wrong', 'حدث خطأ'),
                _ => t('Connection unavailable', 'الاتصال غير متاح'),
              },
        message: t(
          'Draft content is kept. Recovery depends on the error.',
          'يُحتفظ بالمسودة. يعتمد التعافي على نوع الخطأ.',
        ),
        tone: recovered ? BkTone.success : BkTone.danger,
      ),
      BkButton(
        label: switch (errorCode) {
          '401' => t('Preview sign in', 'معاينة تسجيل الدخول'),
          '403' => t('Review role permissions', 'مراجعة صلاحيات الدور'),
          '404' => t('Back to pattern overview', 'العودة إلى الأنماط'),
          _ => t('Retry sample request', 'إعادة المحاولة التجريبية'),
        },
        loading: busy,
        loadingLabel: t('Retrying sample', 'جارٍ إعادة المحاولة'),
        onPressed: () {
          if (errorCode == '401' || errorCode == '403') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PatternDemo(
                  kind: errorCode == '401'
                      ? PatternKind.authentication
                      : PatternKind.permissions,
                  arabic: widget.arabic,
                ),
              ),
            );
          } else if (errorCode == '404') {
            Navigator.of(context).maybePop();
          } else {
            simulate(() {
              recovered = true;
              message = t(
                'Sample recovered. Your draft was kept.',
                'نجحت المعاينة. تم الاحتفاظ بالمسودة.',
              );
            });
          }
        },
      ),
      feedback(),
    ],
  );

  Widget permissions() => BkColumn(
    children: [
      roleChoice(),
      if (role == 'owner')
        BkAlert(
          title: t(
            'Owner-only administration panel',
            'لوحة إدارة خاصة بالمالك',
          ),
          message: t(
            'Visible only for the Owner role in this preview.',
            'تظهر لدور المالك فقط في المعاينة.',
          ),
        ),
      BkButton(
        label: t('Preview restricted deletion', 'معاينة الحذف المقيد'),
        onPressed: !canPerform(role, 'delete')
            ? null
            : () {
                if (!canPerform(role, 'delete')) return;
                setState(
                  () => message = t(
                    'Owner action allowed. No data was deleted.',
                    'إجراء المالك مسموح. لم تُحذف بيانات.',
                  ),
                );
              },
      ),
      Text(
        role == 'owner'
            ? t(
                'Owner can create, update and delete.',
                'يمكن للمالك الإنشاء والتعديل والحذف.',
              )
            : role == 'cashier'
            ? t(
                'Cashier can create/update; deletion is restricted.',
                'يمكن لأمين الصندوق الإنشاء والتعديل؛ الحذف مقيد.',
              )
            : t('Viewer can read only.', 'المشاهد يقرأ فقط.'),
      ),
      Text(
        t(
          'UI preview only. The application server must enforce authorization for every request.',
          'معاينة للواجهة فقط. يجب أن يتحقق الخادم من الصلاحيات لكل طلب.',
        ),
      ),
      feedback(),
    ],
  );
}
