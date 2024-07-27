import 'package:flutter/material.dart';

class MusicPlayerBottomAppBar extends StatefulWidget {

  final List<MusicPlayerBottomAppBarItem> items;
  final String centerItemText;
  final double height;
  final double iconSize;
  final double fontSize;
  final Color? backgroundColor;
  final Color color;
  final Color selectedColor;
  final NotchedShape notchedShape;
  final ValueChanged<int> onTabSelected;

  MusicPlayerBottomAppBar({super.key,
    required this.items,
    this.centerItemText = "",
    this.height = 60.0,
    this.iconSize = 18.0,
    this.fontSize = 12.0,
    this.backgroundColor,
    required this.color,
    required this.selectedColor,
    required this.notchedShape,
    required this.onTabSelected,
  }) {
    assert(items.length == 2 || items.length == 3 || items.length == 4);
  }

  @override
  State<StatefulWidget> createState() => MusicPlayerBottomAppBarState();
}

class MusicPlayerBottomAppBarState extends State<MusicPlayerBottomAppBar> {
  int _selectedIndex = 0;

  void _updateIndex(int index) {
    widget.onTabSelected(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = List.generate(widget.items.length, (int index) {
      return _buildTabItem(
        item: widget.items[index],
        index: index,
        onPressed: _updateIndex,
      );
    });


    return BottomAppBar(
      height: widget.height,
      shape: widget.notchedShape,
      color: widget.backgroundColor,
      notchMargin: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }

  Widget _buildTabItem({
    MusicPlayerBottomAppBarItem? item,
    int index = 0,
    ValueChanged<int>? onPressed,
  }) {
    Color color = _selectedIndex == index ? widget.selectedColor : widget.color;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPressed!(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(item?.animation != null) item!.animation!,
            Icon(item!.iconData, color: color, size: widget.iconSize),
            Text(item.text, style: TextStyle(color: color, fontSize: widget.fontSize),),
          ],
        ),
      ),
    );
  }
}

class MusicPlayerBottomAppBarItem {
  MusicPlayerBottomAppBarItem({required this.iconData, required this.text, this.animation,
    this.unselectedColor, this.selectedColor
  });

  IconData iconData;
  String text;
  Widget? animation;
  final Color? selectedColor;
  final Color? unselectedColor;

}
