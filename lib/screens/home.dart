import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warehouse_management/functions/confirm_dialog.dart';
import 'package:warehouse_management/functions/toast.dart';
import 'package:warehouse_management/screens/global_search_page.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_group_card.dart';

class Home extends StatelessWidget {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newProductGroup = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          right: 10,
        ),
        child: FloatingActionButton(heroTag: null,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    "Add Product Group",
                    style: TextStyle(fontFamily: "Nunito"),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                              color: const Color(0xff000000).withValues(alpha: 0.16),
                            ),
                          ],
                        ),
                        height: 50,
                        child: TextField(
                          textInputAction: TextInputAction.next,
                          key: UniqueKey(),
                          controller: _newProductGroup,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            color: ColorPalette.nileBlue,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Product Group Name",
                            filled: true,
                            fillColor: Colors.transparent,
                            hintStyle: TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 16,
                              color: ColorPalette.nileBlue.withValues(alpha: 0.58),
                            ),
                          ),
                          cursorColor: ColorPalette.timberGreen,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final groupName = _newProductGroup.text.trim();
                          if (groupName.isNotEmpty) {
                            try {
                              final docRef = _firestore
                                  .collection("utils")
                                  .doc("productGroups");
                              final doc = await docRef.get();
                              List<dynamic> tempList = [];
                              if (doc.exists &&
                                  doc.data() != null &&
                                  doc.data()!['list'] is List) {
                                tempList =
                                    List<dynamic>.from(doc.data()!['list']);
                              }
                              if (tempList.contains(groupName)) {
                                showTextToast("Group Name already created");
                              } else {
                                tempList.add(groupName);
                                await docRef.set(
                                  {'list': tempList},
                                  SetOptions(merge: true),
                                );

                                // Also sync to warehouse collection for consistency
                                try {
                                  await _firestore
                                      .collection("warehouse")
                                      .doc("Aa3SUKLQScIhcYYkBB1K")
                                      .collection("product_groups")
                                      .add({
                                    'name': groupName,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } catch (_) {}

                                showTextToast("Added Successfully");
                              }
                            } catch (e) {
                              showTextToast("Error: $e");
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            _newProductGroup.text = "";
                          } else {
                            showTextToast("Enter Valid Name!");
                          }
                        },
                        child: Container(
                          height: 45,
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: ColorPalette.pacificBlue,
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                                color:
                                    const Color(0xff000000).withValues(alpha: 0.16),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "Nunito",
                                color: ColorPalette.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          splashColor: ColorPalette.bondyBlue,
          backgroundColor: ColorPalette.pacificBlue,
          child: const Icon(
            Icons.add,
            color: ColorPalette.white,
          ),
        ),
      ),
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to leave'),
        ),
        child: ColoredBox(
          color: ColorPalette.pacificBlue,
          child: SafeArea(
            child: Container(
              color: ColorPalette.aquaHaze,
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 15,
                    ),
                    width: double.infinity,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: ColorPalette.pacificBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Homepage",
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 28,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              splashColor: ColorPalette.timberGreen,
                              icon: const Icon(
                                Icons.search,
                                color: ColorPalette.timberGreen,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GlobalSearchPage(),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.power_settings_new,
                                color: ColorPalette.timberGreen,
                              ),
                              onPressed: () {
                                showConfirmDialog(
                                    context,
                                    "Are you sure you want to Logout?",
                                    "No",
                                    "Yes", () {
                                  Navigator.of(context).pop();
                                }, () {
                                  Navigator.of(context).pop();
                                  _firebaseAuth.signOut();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                            const Text(
                              "Product Groups",
                              style: TextStyle(
                                color: ColorPalette.timberGreen,
                                fontSize: 20,
                                fontFamily: "Nunito",
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream:
                                    _firestore.collection("utils").snapshots(),
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<
                                          QuerySnapshot<Map<String, dynamic>>>
                                      snapshot,
                                ) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 44,
                                              color: ColorPalette.mandy,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Database Access Notice",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: ColorPalette.timberGreen,
                                                fontFamily: "Nunito",
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "If using a new Firebase project, ensure Cloud Firestore Rules allow read/write.\n${snapshot.error}",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ColorPalette.timberGreen
                                                    .withValues(alpha: 0.7),
                                                fontFamily: "Nunito",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasData) {
                                    List<dynamic> productGroups = [];
                                    for (final doc in snapshot.data!.docs) {
                                      if (doc.id == "productGroups" &&
                                          doc.data().containsKey('list')) {
                                        final list = doc.data()['list'];
                                        if (list is List) {
                                          productGroups =
                                              List<dynamic>.from(list);
                                        }
                                        break;
                                      }
                                    }

                                    if (productGroups.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 48,
                                              color: ColorPalette.timberGreen
                                                  .withValues(alpha: 0.4),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "No product groups found.",
                                              style: TextStyle(
                                                fontFamily: "Nunito",
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: ColorPalette.timberGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              "Tap the + button to add a group.",
                                              style: TextStyle(
                                                fontFamily: "Nunito",
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    productGroups.sort();
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
                                    final int crossAxisCount =
                                        screenWidth > 1200
                                            ? 4
                                            : screenWidth > 750
                                                ? 3
                                                : 2;

                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 2.2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: productGroups.length,
                                      itemBuilder: (context, index) {
                                        return ProductGroupCard(
                                          name: productGroups[index] as String,
                                          key: ValueKey(productGroups[index]),
                                        );
                                      },
                                    );
                                  } else {
                                    return const Center(
                                      child: SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: CircularProgressIndicator(
                                          color: ColorPalette.pacificBlue,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
