// import 'package:bokrah_retail/app/core/services/app_database_service.dart';
// import 'package:bokrah_retail/app/initialzation_dependencies.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class AddBarcodePage extends StatelessWidget {
//   const AddBarcodePage({super.key});
//   addItem(data) async {
//     final _AppDataBaseServices = singelton.get<AppDataBaseServices>();

//     await _AppDataBaseServices.into(_AppDataBaseServices.barcodes)
//         .insert(BarcodesCompanion.insert(data: int.parse(data)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     TextEditingController _data = TextEditingController();
//     return Scaffold(
//       appBar: AppBar(),
//       body: Form(
//           child: Column(
//         children: [
//           TextFormField(
//             controller: _data,
//           )
//         ],
//       )),
//       floatingActionButton: FloatingActionButton(onPressed: () async {
//         addItem(_data.text);
//         context.pop();
//       }),
//     );
//   }
// }
