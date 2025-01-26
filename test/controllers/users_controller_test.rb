# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get users_url
    assert_response :success

    json_response = response.parsed_body
    assert json_response[0]['id'].present?
    assert json_response[0]['name'].present?
    assert json_response[0]['email'].present?
  end

  test 'should create user' do
    assert_difference('User.count') do
      post users_url, params: {
        name: 'new user',
        email: 'new@user.com',
        password: 'password'
      }
    end

    assert_response :created

    json_response = response.parsed_body
    assert json_response['id'].present?
    assert_equal json_response['name'], 'new user'
    assert_equal json_response['email'], 'new@user.com'
  end

  test 'should raise error on create with model error' do
    existing_user = users(:one)

    assert_no_difference('User.count') do
      post users_url, params: {
        name: 'new name',
        email: existing_user.email,
        password: 'abcde123'
      }
    end

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    expected_error = {
      'field' => 'email',
      'message' => 'email already exists'
    }
    assert_includes json_response['errors'], expected_error
  end

  test 'should update user' do
    user = users(:one)
    patch user_url(user), params: {
      name: 'updated name',
      email: 'updated@email.com',
      password_digest: 'new password'
    }
    assert_response :success

    json_response = response.parsed_body
    assert_equal json_response['id'], user.id
    assert_equal json_response['name'], 'updated name'
    assert_equal json_response['email'], 'updated@email.com'
    assert json_response['password'].nil?
  end

  test 'should raise error on update with model error' do
    user = users(:one)
    another_user = users(:two)

    put user_url(user), params: {
      email: another_user.email
    }

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    expected_error = {
      'field' => 'email',
      'message' => 'email already exists'
    }
    assert_includes json_response['errors'], expected_error
  end

  test 'should destroy user' do
    user = users(:one)
    PlaidItem.any_instance.stubs(:remove_item_from_plaid).returns(true)

    assert_difference('User.count', -1) do
      delete user_url(user)
    end

    assert_response :no_content
  end
end
