import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../widgets/myjobwidgets.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  _MyJobsScreenState createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Fetch initial orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OrderController>(context, listen: false);
      controller.clearMyJobs();
      controller.fetchMyJobs();
    });

    // Pagination listener
    _scrollController.addListener(() {
      final controller = Provider.of<OrderController>(context, listen: false);
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !controller.isLoading &&
          controller.hasMoreMyJobs) {
        controller.fetchMyJobs(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text('My Jobs'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              controller.clearMyJobs();
              await controller.fetchMyJobs();
            },
            child: controller.isLoading && controller.myJobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      controller.clearMyJobs();
                      controller.fetchMyJobs();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : controller.myJobs.isEmpty
                ? const Center(
              child: Text(
                'You have no orders at the moment.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: controller.myJobs.length +
                  (controller.hasMoreMyJobs ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.myJobs.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final order = controller.myJobs[index];
                return JobCardWidget(
                  job: order,
                  onAccept: () async {
                    final success =
                    await controller.acceptOrder(order.id);
                    if (success && context.mounted) {
                      EasyLoading.showSuccess(
                          'Order accepted successfully');
                    } else if (context.mounted) {
                      EasyLoading.showError(controller.errorMessage ??
                          'Failed to accept order');
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
