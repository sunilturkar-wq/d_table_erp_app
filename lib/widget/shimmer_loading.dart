import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListLoading extends StatelessWidget {
  final int itemCount;
  const ShimmerListLoading({Key? key, this.itemCount = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
              ),
              title: Container(
                height: 16,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8), // Gap
                width: double.infinity,
              ),
              subtitle: Container(
                height: 14,
                color: Colors.white,
                width: 150,
              ),
              trailing: Container(
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
