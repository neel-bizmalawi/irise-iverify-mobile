// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
// import 'package:irise/core/services/connectivity_service.dart';
// import 'package:irise/route/app_routes.dart';

// class ConnectivityBanner extends StatelessWidget {
//   final Widget child;

//   const ConnectivityBanner({
//     super.key,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ConnectivityService>(
//       builder: (context, connectivityService, _) {
//         return Builder(
//           builder: (builderContext) {
//             // Get current route location safely
//             String? location;
//             try {
//               location = GoRouter.of(builderContext).routerDelegate.currentConfiguration.uri.toString();
//             } catch (e) {
//               // If we can't get the route, default to showing the banner
//               location = null;
//             }
            
//             // Don't show banner on dashboard/home screen
//             final shouldShowBanner = location != AppRoutes.dashboard && 
//                                      !connectivityService.isConnected;
            
//             return Stack(
//               children: [
//                 child,
//                 if (shouldShowBanner)
//                   Positioned(
//                     top: 0,
//                     left: 0,
//                     right: 0,
//                     child: SafeArea(
//                       child: Material(
//                         color: Colors.transparent,
//                         child: Container(
//                           margin: const EdgeInsets.all(16),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade600,
//                             borderRadius: BorderRadius.circular(8),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withValues(alpha: 0.2),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: const Row(
//                             children: [
//                               Icon(
//                                 Icons.wifi_off,
//                                 color: Colors.white,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   'No internet connection',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
