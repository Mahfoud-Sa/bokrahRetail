// import 'package:bokrah_retail/app/core/services/app_database_service.dart';
// import 'package:bokrah_retail/app/initialzation_dependencies.dart';
// import 'package:flutter/material.dart';

// class InvoicesPage extends StatefulWidget {
//   const InvoicesPage({super.key});

//   @override
//   State<InvoicesPage> createState() => _InvoicesPageState();
// }

// class _InvoicesPageState extends State<InvoicesPage> {
//   getItems() async {
//     final _AppDataBaseServices = singelton.get<AppDataBaseServices>();

//     List<dynamic> allItems =
//         await _AppDataBaseServices.select(_AppDataBaseServices.items).get();
//     return allItems;
//   }

//   addItem() async {
//     final _AppDataBaseServices = singelton.get<AppDataBaseServices>();

//     await _AppDataBaseServices.into(_AppDataBaseServices.items)
//         .insert(ItemsCompanion.insert(
//       name: 'todo: finish drift setup',
//       description: 'We can now write queries and define our own tables.',
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder(
//         future: getItems(),
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             return Text(snapshot.data!.toString());
//           } else if (snapshot.hasError) {
//             return Text('${snapshot.error}');
//           }

//           // By default, show a loading spinner.
//           return const CircularProgressIndicator();
//         },
//       ),
//       floatingActionButton: FloatingActionButton(onPressed: () async {
//         setState(() {
//           addItem();
//         });
//       }),
//     );
//   }
// }
