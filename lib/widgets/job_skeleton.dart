import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class JobSkeleton extends StatelessWidget {
  const JobSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 50, height: 50, color: Colors.white), // Giả icon
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16, color: Colors.white), // Giả title
                        const SizedBox(height: 8),
                        Container(width: 100, height: 14, color: Colors.white), // Giả company
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: 200, height: 12, color: Colors.white), // Giả tags
            ],
          ),
        ),
      ),
    );
  }
}