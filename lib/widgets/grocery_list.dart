import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/data/categories.dart';

import '../models/grocery_item.dart';
import 'new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  String? _error;
  var _isLoading = true;
  void _loadItems() async {
    final url = Uri.https(
        'flutter-http-974de-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list.json');
    final result = await http.get(url);
    if(result.statusCode >=400){
      setState(() {
        _error = 'Server error';
      });
    }
    if(result.body== 'null'){
      setState(() {
        _error = 'Failed to fetch';
      });
    }
    final Map<String,dynamic> listData = json.decode(result.body);
    final List<GroceryItem> loadItems = [];
    for(final item in listData.entries){
      final category = categories.entries.firstWhere((element) => element.value.title == item.value['category']).value;
      loadItems.add(GroceryItem(id: item.key, name: item.value['name'], quantity: item.value['quantity'], category: category));
    }
    setState(() {
      _groceryItems = loadItems;
      _isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadItems();
  }
  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem()));
  if(newItem==null){
    return;
  }
  setState(() {
    _groceryItems.add(newItem);
  });
  }
  void _removeItem(GroceryItem item) async{
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        'flutter-http-974de-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if(response.statusCode>=400){
      setState(() {
        _groceryItems.insert(index,item);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items'),);
    if(_isLoading){
      content = const Center(child: CircularProgressIndicator(),);
    }
    if(_groceryItems.isNotEmpty){
      content =ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
            onDismissed: (direction){
              _removeItem(_groceryItems[index]);
            },
            key: ValueKey(_groceryItems[index].id),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(_groceryItems[index].quantity.toString()),
            ),
          ));
    }
    if(_error !=null){
      content = Center(child: Text(_error!),);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
        ],
      ),
      body: content
    );
  }
}
