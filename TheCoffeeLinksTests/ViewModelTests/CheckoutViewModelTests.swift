import XCTest
@testable import TheCoffeeLinks

@MainActor
final class CheckoutViewModelTests: XCTestCase {
    private var orderRepository: MockOrderRepository!
    private var predictionRepository: MockPredictionRepository!
    private var analyticsService: MockAnalyticsService!
    private var hapticService: MockHapticService!
    private var orderStorage: InMemoryOrderStorage!
    private var viewModel: CheckoutViewModel!

    override func setUp() {
        super.setUp()
        orderRepository = MockOrderRepository()
        predictionRepository = MockPredictionRepository()
        analyticsService = MockAnalyticsService()
        hapticService = MockHapticService()
        orderStorage = InMemoryOrderStorage()
        viewModel = CheckoutViewModel(
            orderRepository: orderRepository,
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            predictionRepository: predictionRepository,
            analyticsService: analyticsService,
            hapticService: hapticService,
            orderStorage: orderStorage
        )
    }

    func testEmptyCartCannotPlaceOrder() async {
        let order = await viewModel.placeOrder(cart: .empty)

        XCTAssertNil(order)
        XCTAssertFalse(viewModel.isPlacingOrder)
        XCTAssertTrue(viewModel.error is CheckoutError)
        XCTAssertTrue(orderRepository.createdRequests.isEmpty)
    }

    func testUnavailableStoreItemBlocksBeforeNetworkCall() async {
        let unavailable = TestFactory.product(isStoreAvailable: false)
        let cart = TestFactory.cart(items: [TestFactory.cartItem(product: unavailable)], storeId: "store-d1")

        let order = await viewModel.placeOrder(cart: cart)

        XCTAssertNil(order)
        XCTAssertFalse(viewModel.isPlacingOrder)
        XCTAssertTrue(orderRepository.createdRequests.isEmpty)
    }

    func testPaymentUrlOrderOpensPaymentWebViewAndKeepsPendingOrderId() async {
        let paidOrder = TestFactory.order(id: "order-pay", paymentUrl: "https://sandbox.vnpayment.vn/pay")
        orderRepository.createResult = .success(paidOrder)
        let cart = TestFactory.cart()

        let returnedOrder = await viewModel.placeOrder(cart: cart, pointsToRedeem: 0, voucherCode: nil)

        XCTAssertNil(returnedOrder)
        XCTAssertTrue(viewModel.showingPaymentWebView)
        XCTAssertEqual(viewModel.paymentUrl?.absoluteString, "https://sandbox.vnpayment.vn/pay")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "pendingPaymentOrderId"), "order-pay")
        XCTAssertEqual(orderRepository.createdRequests.first?.idempotencyKey?.isEmpty, false)
        XCTAssertTrue(predictionRepository.recordedOrders.isEmpty)
    }

    func testSuccessfulOrderWithoutPaymentUrlRecordsPurchaseAndClearsDraft() async {
        let completedOrder = TestFactory.order(id: "order-free", paymentUrl: nil)
        orderRepository.createResult = .success(completedOrder)
        let cart = TestFactory.cart()

        let returnedOrder = await viewModel.placeOrder(cart: cart, pointsToRedeem: 5, voucherCode: "WELCOME")

        XCTAssertEqual(returnedOrder?.id, "order-free")
        XCTAssertEqual(viewModel.orderPlaced?.id, "order-free")
        XCTAssertFalse(viewModel.showingPaymentWebView)
        XCTAssertEqual(predictionRepository.recordedOrders.count, 1)
        XCTAssertEqual(analyticsService.purchases.first?.0, "order-free")
        XCTAssertTrue(orderStorage.didClearDraft)
        XCTAssertEqual(orderRepository.createdRequests.first?.pointsToRedeem, 5)
        XCTAssertEqual(orderRepository.createdRequests.first?.voucherCode, "WELCOME")
    }

    func testRepositoryFailureSurfacesErrorAndDoesNotClearDraft() async {
        orderRepository.createResult = .failure(TestError.requestedFailure)

        let returnedOrder = await viewModel.placeOrder(cart: TestFactory.cart())

        XCTAssertNil(returnedOrder)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(orderStorage.didClearDraft)
        XCTAssertEqual(hapticService.notifications.last, .error)
    }
}
