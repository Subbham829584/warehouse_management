import 'package:flutter/material.dart';
import 'package:warehouse_management/services/warehouse_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class SearchProductInGroupPage extends StatefulWidget {
  final String? name;
  const SearchProductInGroupPage({Key? key, this.name}) : super(key: key);

  @override
  State<SearchProductInGroupPage> createState() =>
      _SearchProductInGroupPageState();
}

class _SearchProductInGroupPageState extends State<SearchProductInGroupPage> {
  late final TextEditingController _controller;
  FocusNode? inputFieldNode;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    inputFieldNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    inputFieldNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: inputFieldNode,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          onSubmitted: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          textInputAction: TextInputAction.search,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 22,
                            color: ColorPalette.timberGreen,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search in ${widget.name ?? 'group'}...",
                            filled: true,
                            fillColor: Colors.transparent,
                            hintStyle: TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 18,
                              color: ColorPalette.timberGreen.withOpacity(0.58),
                            ),
                          ),
                          cursorColor: ColorPalette.timberGreen,
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: ColorPalette.timberGreen,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          child: searchQuery.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        size: 48,
                                        color: Colors.black26,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Search items inside ${widget.name ?? 'this group'}",
                                        style: const TextStyle(
                                          fontFamily: "Nunito",
                                          color: ColorPalette.timberGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : StreamBuilder<List<WarehouseProductItem>>(
                                  stream: WarehouseService.instance
                                      .searchProductsStream(
                                    searchQuery,
                                    group: widget.name,
                                  ),
                                  builder: (
                                    BuildContext context,
                                    AsyncSnapshot<List<WarehouseProductItem>>
                                        snapshot,
                                  ) {
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
                                    final items = snapshot.data!;
                                    if (items.isEmpty) {
                                      return Center(
                                        child: Text(
                                          "No products found in ${widget.name} matching '$searchQuery'",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: "Nunito",
                                            fontSize: 16,
                                            color: ColorPalette.timberGreen,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: items.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return ProductCard(
                                          product: items[index].product,
                                          docID: items[index].id,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
