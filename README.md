

## users テーブル
|Column|Type|Options|
|------|----|-------|
|avatar_image   |text   |                                   <!-- アイコン -->
|introduction   |text   |                                   <!-- 自己紹介文 -->
|nickname       |string |null: false|                       <!-- ニックネーム -->
|email          |string |null: false, add_index, unique :true|<!-- メアド -->
|password       |string |null: false|                       <!-- パス --> 
|last_name      |string |null: false|                       <!-- 苗字 -->
|first_name     |string |null: false|                       <!-- 名前 -->
|last_name_kana |string |null: false|                       <!-- 苗字（カナ） -->
|first_name_kana|string |null: false|                       <!-- 名前(カナ) -->
|birthday       |date   |null: false|                       <!-- 誕生日 --> 
### Association
has_many :likes
has_many :addresses
has_many :commnets
has_many :items
has_many :reviews





## addresses テーブル
|Column|Type|Options|
|------|----|-------|
|postcode |string |null: false|                              <!-- 郵便番号 -->
|city     |string |null: false|                              <!-- 市町村 -->
|block    |string |null: false|                              <!-- 番地 -->
|building |string |                                          <!-- 建物名 任意-->
|tell     |string |null: false, add_index, unique :true|     <!-- 電話番号 -->
|user_id  |integer|null: false, foreign_key: true|           <!-- 外部キー-->
### Association
belongt_to :user


## items テーブル
|Column|Type|Options|
|------|----|-------|
|name           |string |null: fals|
|text           |text   |null: fals|              <!-- 商品説明欄-->
|status         |integer|default: 0, null: false| <!-- 商品状態 enum-->
|delivery_method|integer|default: 0, null: false| <!-- 配送方法 enum-->
|delivery_day   |integer|default: 0, null: false| <!-- 配送までの日数 enum-->
|pref           |integer|default: 0, null: false| <!-- 発送地域--> 
|postage_selct  |integer|default: 0, null: false| <!-- 送料負担-->
|price          |integer|null: false|              <!-- 価格-->
|size           |integer|default: 0|              <!-- サイズ enum-->
|user_id        |null: false, foreign_key: true|
|brand_id       |null: false, foreign_key: true|
### Association
has_many :likes
has_many :comments
has_many :photos
has_many :items_catgoriess
has_many :category through: :items_catgories
belongs_to :brand
belongs_to :user


## categories テーブル
|Column|Type|Options|
|------|----|-------|
|genre   |integer|default: 0,null false|<!-- カテゴリ大-->
|subgenre|integer|default: 0,null false|<!-- カテゴリ中-->
|detail  |integer|default: 0,null false|<!-- カテゴリ小-->
### Association
has_many :items_catgories
has_many :items through: :items_catgoriess



## items_categories テーブル（中間テーブル）
|Column|Type|Options|
|------|----|-------|
|item_id    |null: false, foreign_key: true|<!-- 外部キー-->
|category_id|null: false, foreign_key: true|<!-- 外部キー-->
### Association
belongs_to :item
belongs_to :category


## photo テーブル
|Column|Type|Options|
|------|----|-------|
|url    |text   |null: false|<!-- 最低一枚必須？--><!-- 商品写真-->
|item_id|integer|null: false,foreign_key: true|
### Association
belongs_to :item


##  brand テーブル
|Column|Type|Options|
|------|----|-------|
|name  |strung|           <!-- カテゴリー選択後必要なら--><!-- ブランド名-->
### Association
hasmany :items



## likes
|Column|Type|Options|
|------|----|-------|              
|item_id|integer|null false,foreign_key: true|<!-- 外部キー -->
|user_id|integer|null false,foreign_key: true|<!-- 外部キー -->
### Association
belongs_to :item
belongs_to :user

## comment
|Column|Type|Options|
|------|----|-------|
|messge |text   |null: false|<!-- コメント-->
|item_id|integer|null false,foreign_key: true|<!-- item外部キー -->
|user_id|integer|null false,foreign_key: true|<!-- user外部キー -->
### Association
belongs_to :user
belongs_to :item

## review
|Column|Type|Options|
|------|----|-------|
|evaluation |integer|null: false|<!-- 評価    enum-->
|message    |text   |null: false|<!-- 評価文  enum-->
|user_id    |integer|null false,foreign_key: true|<!-- user外部キー -->
### Association
belongs_to :user






# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  require 'payjp'
  #1本人情報登録
  def new 
    #インスタンス作成
    @user = User.new
  end

  #本人情報(post)
  def create                                  #(ユーザー情報)
    @user = User.new(sign_up_params)          #データの代入(ユーザー情報)
    #バリデーション
    unless @user.valid?
      flash.now[:alert] = @user.errors.full_messages
      render :new and return
    end
    session["devise.regist_data"] = {user: @user.attributes}
    session["devise.regist_data"][:user]["password"] = params[:user][:password]
    #インスタンス作成
    @number = @user.build_phone_number        
    render :new_tellphone
  end

  #2電話番号確認(post)
  def create_tellphone                                                
    @number = PhoneNumber.new(user_params)                            #データの代入(電話番号)
    #セッションの作成
    session["devise.regist_data2"] = {phoneNumber: @number.attributes}
    @user = User.new(session["devise.regist_data"]["user"])
    @address = @user.build_address           
    #インスタンス作成
    render :new_address
  end
  

  #3お届け先住所(post)
  def create_address
    @user = User.new(session["devise.regist_data"]["user"])           # セッションの代入(ユーザー情報)
    @number = PhoneNumber.new(number: session["devise.regist_data2"])
    @address = Address.new(address_params)                            #データの代入(お届け先住所)
    #バリデーション
    unless @address.valid?
      flash.now[:alert] = @address.errors.full_messages
      render :new_address and return
    end
    #セッションの作成
    session["devise.regist_data3"] = {address: @address.attributes}
    @user.build_address(@address.attributes)
    @user.save
    sign_in(:user, @user)
    @card = Card.new
    render :new_cards
  end


  #4お支払い方法
  # クレジットカード情報入力画面

  def new_cards
    redirect_to root_path unless user_signed_in?
    if @card
      redirect_to card_path unless @card
    else
    end
  end

  def create_cards
    Payjp.api_key = "sk_test_f67be4ad1051de6822903d38"
    if params['payjp-token'].blank?
      redirect_to root_path
    else
      customer = Payjp::Customer.create( # ここで先ほど生成したトークンを顧客情報と紐付け、PAY.JP管理サイトに送信
        email: current_user.email,
        card: params['payjp-token'],
        metadata: {user_id: current_user.id} # 記述しなくても大丈夫です
      )
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to root_path
      else
      end
    end
  end
  #5完了ページ
  #def create_finish
  #  @user     = User.new(session["devise.regist_data"]["user"])        #1セッションの代入(ユーザー情報)
  #  @number   = PhoneNumber.new(number: session["devise.regist_data2"])#2セッションの代入(電話番号)
  #  @@address = Address.new(number: session["devise.regist_data3"])    #3セッションの代入(お届け先住所)
  #  @card     = Card.new(card: session["devise.regist_data4"])         #4セッションの代入(お支払い情報)
  #end


  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  end    

  def user_params
    params.require(:phone_number).permit(:number)
  end

  def address_params
    params.require(:address).permit(:postcode, :city, :block, :building, :tell)
  end

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end







