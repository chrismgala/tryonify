import React, { useState, useCallback, useEffect } from 'react';
import {
  Badge,
  Button,
  Card,
  Form,
  FormLayout,
  Page,
  Layout,
  Stack,
  Tag,
  TextField as InputField,
} from '@shopify/polaris';
import { useToast } from '@shopify/app-bridge-react';
import { Formik, Field, FieldArray } from 'formik';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SaveBar from '../../components/save-bar';
import TextField from '../../components/text-field';
import CheckboxField from '../../components/checkbox-field';

const initialValues = {
  klaviyoPublicKey: '',
  klaviyoPrivateKey: '',
  returnPeriod: 14,
  returnExplainer: '',
  allowAutomaticPayments: true,
  cancelPrepaidCards: true,
  reauthorizePaypal: true,
  reauthorizeShopifyPayments: true,
};

export default function Settings() {
  const toast = useToast();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [tag, setTag] = useState('');
  const { isLoading, error, data } = useAppQuery({
    url: "/api/v1/shop"
  });
  const saveMutation = useMutation(
    (shop) => fetch('/api/v1/shop', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(shop)
    }).then(async (response) => await response.json()),
    {
      onSuccess: (response) => {
        queryClient.setQueryData("/api/v1/shop", response);
      },
    }
  );
  const redirectHost = process.env.HOST;

  const onSubmit = useCallback(async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  }, [saveMutation]);

  const handleTagChange = useCallback((value) => {
    setTag(value);
  }, []);

  const handleTagAdd = useCallback(arrayHelpers => {
    arrayHelpers.push(tag);
    setTag('');
  }, [tag])

  useEffect(() => {
    if (saveMutation.isSuccess) toast.show('Save successful!', { duration: 2000 })
  }, [saveMutation.isSuccess])

  if (isLoading) {
    return null;
  }

  return (
    <Page title="Settings">
      <Formik
        initialValues={{
          ...initialValues,
          ...data?.shop,
        }}
        onSubmit={onSubmit}
      >
        {({
          handleSubmit, resetForm, submitForm, dirty, values,
        }) => (
          <Form onSubmit={handleSubmit}>
            <SaveBar dirty={dirty} submitForm={submitForm} resetForm={resetForm} />
            <Layout>
              <Layout.AnnotatedSection
                title="General"
                description="Settings for general behavior of the application."
              >
                <Card sectioned>
                  <FormLayout>
                    <Field
                      label="Max trial items per order"
                      name="maxTrialItems"
                      autoComplete="off"
                      component={TextField}
                    />
                    <FieldArray name="allowedTags">
                      {arrayHelpers => (
                        <Stack vertical>
                          <InputField
                            label="Restrict trials to customers with allowed tags"
                            autoComplete="off"
                            onChange={handleTagChange}
                            value={tag}
                            verticalContent={
                              (values?.allowedTags && values?.allowedTags.length > 0) ?
                                <Stack spacing="extraTight" alignment="center">
                                  {values?.allowedTags?.map((tag, index) =>
                                    <Tag key={tag} onRemove={() => arrayHelpers.remove(index)}>{tag}</Tag>
                                  )}
                                </Stack>
                                : null
                            }
                          />
                          <Button type="button" onClick={() => handleTagAdd(arrayHelpers)}>Add Tag</Button>
                        </Stack>
                      )}
                    </FieldArray>
                  </FormLayout>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Payments"
                description="How your program handles payments from the customer."
              >
                <Card>
                  <Card.Section>
                    <FormLayout>
                      <Field
                        label="Allow automatic payments"
                        name="allowAutomaticPayments"
                        component={CheckboxField}
                      />
                      <Field
                        label={<span>Authorize new orders <Badge>Beta</Badge></span>}
                        name="authorizeTransactions"
                        component={CheckboxField}
                      />
                      <Field
                        label={<span>Cancel orders using pre-paid cards <Badge>Beta</Badge></span>}
                        name="cancelPrepaidCards"
                        component={CheckboxField}
                        helpText="Requires a checkout charge on trial plan or payment authorization"
                      />
                    </FormLayout>
                  </Card.Section>
                  <Card.Section title="Shopify Payments">
                    <Field
                      label="Re-authorize transactions"
                      name="reauthorizeShopifyPayments"
                      component={CheckboxField}
                    />
                  </Card.Section>
                  <Card.Section title="PayPal Payments">
                    <Field
                      label="Re-authorize transactions"
                      name="reauthorizePaypal"
                      component={CheckboxField}
                    />
                  </Card.Section>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Returns"
                description="Customize how returns are handled for trial orders."
              >
                <Card sectioned>
                  <FormLayout>
                    <Field
                      label="Return Period (Days)"
                      name="returnPeriod"
                      component={TextField}
                      helpText="How many days customers have to complete a return before they are charged."
                    />
                    <Field
                      label="Instructions"
                      name="returnExplainer"
                      component={TextField}
                      multiline={3}
                      helpText="This text will appear above the return form when customers find their order."
                    />
                  </FormLayout>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Integrations"
                description="Connect TryOnify with other applications you use."
              >
                <Card title="Klaviyo" sectioned>
                  <FormLayout>
                    <Field
                      label="Public Key"
                      name="klaviyoPublicKey"
                      component={TextField}
                    />
                    <Field
                      label="Private Key"
                      name="klaviyoPrivateKey"
                      component={TextField}
                      type="password"
                    />
                  </FormLayout>
                </Card>
                <Card title="Slack" sectioned>
                  <a
                    href={`https://slack.com/oauth/v2/authorize?scope=channels:read,chat:write&redirect_uri=${encodeURIComponent(`https://${redirectHost}`)}%2Fapi%2Fv1%2Fslack&client_id=4470812349095.4470845636199&state=${encodeURIComponent(`${data?.shop?.shopifyDomain}:${data?.shop?.key}`)}`}
                    style={{
                      alignItems: 'center',
                      color: '#000',
                      backgroundColor: '#fff',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      display: 'inline-flex',
                      fontFamily: 'Lato, sans-serif',
                      fontSize: '16px',
                      fontWeight: '600',
                      height: '48px',
                      justifyContent: 'center',
                      textDecoration: 'none',
                      width: '236px',
                    }}
                    target="_blank"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" style={{ height: '20px', width: '20px', marginRight: '12px' }} viewBox="0 0 122.8 122.8">
                      <path d="M25.8 77.6c0 7.1-5.8 12.9-12.9 12.9S0 84.7 0 77.6s5.8-12.9 12.9-12.9h12.9v12.9zm6.5 0c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9v32.3c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V77.6z" fill="#e01e5a" />
                      <path d="M45.2 25.8c-7.1 0-12.9-5.8-12.9-12.9S38.1 0 45.2 0s12.9 5.8 12.9 12.9v12.9H45.2zm0 6.5c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H12.9C5.8 58.1 0 52.3 0 45.2s5.8-12.9 12.9-12.9h32.3z" fill="#36c5f0" />
                      <path d="M97 45.2c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9-5.8 12.9-12.9 12.9H97V45.2zm-6.5 0c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V12.9C64.7 5.8 70.5 0 77.6 0s12.9 5.8 12.9 12.9v32.3z" fill="#2eb67d" />
                      <path d="M77.6 97c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9-12.9-5.8-12.9-12.9V97h12.9zm0-6.5c-7.1 0-12.9-5.8-12.9-12.9s5.8-12.9 12.9-12.9h32.3c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H77.6z" fill="#ecb22e" />
                    </svg>
                    Add to Slack
                  </a>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.Section />
            </Layout>
          </Form>
        )}
      </Formik>
    </Page>
  );
}
