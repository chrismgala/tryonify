import React from 'react';
import PropTypes from 'prop-types';
import {
  Layout,
  Card,
  Form,
  FormLayout,
} from '@shopify/polaris';
import { Formik, Field } from 'formik';
import * as Yup from 'yup';
import TextField from './text-field';
import SaveBar from './save-bar';

const validationSchema = Yup.object().shape({
  name: Yup.string().required('Name is required'),
  description: Yup.string().nullable(),
  sellingPlan: Yup.object().shape({
    name: Yup.string().required('Name is required'),
    description: Yup.string().nullable(),
    prepay: Yup.number().required('Pre-paid amount is required'),
    trialDays: Yup.number().required('Trial days required'),
  }),
});

export default function SellingPlanForm({
  initialValues,
  onSubmit,
  formRef,
}) {
  return (
    <Formik
      initialValues={initialValues}
      validationSchema={validationSchema}
      onSubmit={onSubmit}
    >
      {({
        handleSubmit, resetForm, submitForm, dirty,
      }) => (
        <Form onSubmit={handleSubmit}>
          <SaveBar dirty={dirty} submitForm={submitForm} resetForm={resetForm} />
          <Layout>
            <Layout.Section>
              <Card title="Admin Details" sectioned>
                <FormLayout>
                  <Field
                    label="Name"
                    name="name"
                    component={TextField}
                    helpText="Name administrators will see."
                  />

                  <Field
                    label="Description"
                    name="description"
                    multiline={4}
                    component={TextField}
                    helpText="Description administrators will see."
                  />
                </FormLayout>
              </Card>
              <Card title="Customer Details" sectioned>
                <FormLayout>
                  <Field
                    label="Name"
                    name="sellingPlan[name]"
                    component={TextField}
                    helpText="Name customers will see."
                  />

                  <Field
                    label="Description"
                    name="sellingPlan[description]"
                    multiline={4}
                    component={TextField}
                    helpText="Description customers will see."
                  />
                </FormLayout>
              </Card>
            </Layout.Section>
            <Layout.Section secondary>
              <Card title="Payment Terms" sectioned>
                <FormLayout>
                  <Field
                    label="Pre-paid Amount"
                    name="sellingPlan[prepay]"
                    type="number"
                    component={TextField}
                  />

                  <Field
                    label="Trial Length (Days)"
                    name="sellingPlan[trialDays]"
                    type="number"
                    component={TextField}
                  />
                </FormLayout>
              </Card>
            </Layout.Section>
          </Layout>
          <input type="submit" ref={formRef} style={{ display: 'none' }} value="Save" />
        </Form>
      )}
    </Formik>
  );
}

SellingPlanForm.propTypes = {
  initialValues: PropTypes.shape({
    name: PropTypes.string,
    description: PropTypes.string,
    sellingPlansAttributes: PropTypes.arrayOf(PropTypes.shape({
      name: PropTypes.string,
      description: PropTypes.string,
      prepay: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
      trialDays: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    })),
  }).isRequired,
  onSubmit: PropTypes.func.isRequired,
  formRef: PropTypes.shape({}).isRequired,
};
