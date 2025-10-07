import { Crisp } from "crisp-sdk-web";

const initializeCrisp = (shop) => {
    Crisp.configure('05a5de57-8698-4812-9982-58a143a2ef07');

    Crisp.setSafeMode(true);

    Crisp.user.setEmail(shop.email);
    Crisp.user.setCompany(shop.email, {
        url: `https://${shop.shopify_domain}`
    });

    Crisp.session.setData([
        ["shop_id", shop.id],
        ["currency_code", shop.currency_code],
        ["return_period", shop.return_period],
        ["allow_automatic_payments", shop.allow_automatic_payments],
        ["max_trial_items", shop.max_trial_items],
        ["void_authorizations", shop.void_authorizations],
        ["authorize_transactions", shop.authorize_transactions],
        ["cancel_prepaid_cards", shop.cancel_prepaid_cards],
        ["reauthorize_shopify_payments", shop.reauthorize_shopify_payments],
        ["reauthorize_paypal", shop.reauthorize_paypal],
    ]);
}

export default initializeCrisp;
