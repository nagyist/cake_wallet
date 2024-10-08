import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollableWithBottomSection extends StatefulWidget {
  ScrollableWithBottomSection({
    required this.content,
    required this.bottomSection,
    this.topSection,
    this.contentPadding,
    this.bottomSectionPadding,
    this.topSectionPadding,
    this.scrollableKey,
  });

  final Widget content;
  final Widget bottomSection;
  final Widget? topSection;
  final EdgeInsets? contentPadding;
  final EdgeInsets? bottomSectionPadding;
  final EdgeInsets? topSectionPadding;
  final Key? scrollableKey;

  @override
  ScrollableWithBottomSectionState createState() => ScrollableWithBottomSectionState();
}

class ScrollableWithBottomSectionState extends State<ScrollableWithBottomSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.topSection != null)
          Padding(
            padding: widget.topSectionPadding?.copyWith(top: 10) ??
                EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
            child: widget.topSection,
          ),
        Expanded(
          child: SingleChildScrollView(
            key: widget.scrollableKey,
            child: Padding(
              padding: widget.contentPadding ?? EdgeInsets.only(left: 20, right: 20),
              child: widget.content,
            ),
          ),
        ),
        Padding(
          padding: widget.bottomSectionPadding?.copyWith(top: 10) ??
              EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
          child: widget.bottomSection,
        ),
      ],
    );
  }
}
