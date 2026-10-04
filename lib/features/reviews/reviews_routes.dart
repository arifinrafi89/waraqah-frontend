import 'package:go_router/go_router.dart';

import 'presentation/pages/book_reviews_page.dart';

abstract final class ReviewsRoutes {
  /// Every review of one Book; open to guests.
  static const String reviews = '/reviews';

  static String forBook(String bookId) =>
      Uri(path: reviews, queryParameters: {'bookId': bookId}).toString();

  static final List<RouteBase> routes = [
    GoRoute(
      path: reviews,
      // Reviews belong to one Book; without one there is nothing to show.
      redirect: (_, state) =>
          (state.uri.queryParameters['bookId'] ?? '').isEmpty
          ? '/catalog'
          : null,
      builder: (_, state) =>
          BookReviewsPage(bookId: state.uri.queryParameters['bookId'] ?? ''),
    ),
  ];
}
