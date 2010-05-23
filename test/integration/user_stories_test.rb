
require 'test_helper'

class UserStoriesTest < ActionController::IntegrationTest
  fixtures :products

  test "buying a product" do

    # remove existing data
    LineItem.delete_all
    Order.delete_all

    # get a product fixture
    ruby_book = products(:ruby)

    # start at the front page
    get "/"
    assert_response :success
    assert_template "index"
    
    # add item to cart via AJAX call
    xml_http_request :post, '/line_items',
      :product_id => ruby_book.id
    assert_response :success
    
    # ensure the correct item(s) are in the cart
    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product
    
    # begin checkout
    get "/orders/new"
    assert_response :success
    assert_template "new"
    
    # finish checkout
    post_via_redirect "/orders", :order => {
      :name	    => "Dave Thomas",
      :address  => "123 The Street",
      :email	  => "dave@example.com",
      :pay_type => "Check"
    }
    assert_response :success
    assert_template "index"
    
    # ensure cart is now empty
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size
    
    # ensure order was placed
    orders = Order.find(:all)
    assert_equal 1, orders.size
    
    # ensure order data is correct
    order = orders[0]
    assert_equal "Dave Thomas",	order.name
    assert_equal "123 The Street",	order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check",	order.pay_type
    
    # ensure line items are correct
    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product

    # ensure email confirmation was sent correctly
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject
  end

end
