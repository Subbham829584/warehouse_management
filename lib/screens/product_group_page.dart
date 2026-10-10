import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warehouse_management/functions/confirm_dialog.dart';
import 'package:warehouse_management/functions/toast.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/new_product_page.dart';
import 'package:warehouse_management/screens/search_product_in_group.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class ProductGroupPage extends StatelessWidget {
  final String? name;
  ProductGroupPage({Key? key, this.name}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          right: 10,
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return NewProductPage(
                    group: name,
                  );
                },
              ),
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
      body: Container(
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
                    left: 10,
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 35,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(
                            name!.length > 14
                                ? '${name!.substring(0, 12)}..'
                                : name!,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 28,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                        ],
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
                                      SearchProductInGroupPage(
                                    name: name,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: ColorPalette.timberGreen,
                            ),
                            onPressed: () {
                              showConfirmDialog(
                                context,
                                "Are you sure you want to delete '$name' group?",
                                "No",
                                "Yes",
                                () {
                                  Navigator.of(context).pop();
                                },
                                () async {
                                  Navigator.of(context).pop();
                                  try {
                                    final docRef = _firestore
                                        .collection("utils")
                                        .doc("productGroups");
                                    final doc = await docRef.get();
                                    if (doc.exists &&
                                        doc.data() != null &&
                                        doc.data()!['list'] is List) {
                                      final list = List<dynamic>.from(
                                          doc.data()!['list']);
                                      list.remove(name);
                                      await docRef.update({'list': list});
                                    }
                                    showTextToast('Product Group Deleted!');
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    showTextToast('Failed to delete group: $e');
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      )
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
                          Row(
                            children: const [
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                          const Text(
                            "Products",
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
                              stream: _firestore
                                  .collection("products")
                                  .where("group", isEqualTo: name)
                                  .snapshots(),
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<
                                        QuerySnapshot<Map<String, dynamic>>>
                                    snapshot,
                              ) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        "Error loading products: ${snapshot.error}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: ColorPalette.mandy,
                                          fontFamily: "Nunito",
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData) {
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

                                final docs = snapshot.data!.docs.toList();
                                docs.sort((a, b) {
                                  final aName = (a.data()['name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final bName = (b.data()['name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return aName.compareTo(bName);
                                });

                                if (docs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 48,
                                          color: ColorPalette.timberGreen
                                              .withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "No products in this group yet.",
                                          style: TextStyle(
                                            fontFamily: "Nunito",
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: ColorPalette.timberGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Tap + below to add your first product.",
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

                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return ProductCard(
                                      product: Product.fromMap(
                                        docs[index].data(),
                                      ),
                                      docID: docs[index].id,
                                    );
                                  },
                                );
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
    );
  }
}
