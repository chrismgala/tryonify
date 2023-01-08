import React from 'react';
import { I18nContext, I18nManager } from "@shopify/react-i18n";
import { useAppQuery } from '../../hooks';

export function I18nProvider({ children }) {
  const {
    isLoading,
    data,
  } = useAppQuery({
    url: "/api/v1/shop"
  });

  if (isLoading) return null;

  const i18nManager = new I18nManager({
    locale: 'en',
    currency: data?.shop?.currencyCode,
  });

  return (
    <I18nContext.Provider value={i18nManager}>
      {children}
    </I18nContext.Provider>
  )
}