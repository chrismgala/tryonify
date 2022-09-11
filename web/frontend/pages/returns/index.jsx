import React, { useCallback } from 'react';
import { Formik, Form, Field } from 'formik';
import { useNavigate, useLocation } from 'react-router-dom';
import styles from './index.module.css';

export default function Returns() {
  const navigate = useNavigate();
  const { search } = useLocation();

  const queryParams = new URLSearchParams(search);

  const validate = (values) => {
    const errors = {};

    if (!values.name) {
      errors.name = 'Required';
    }

    if (!values.email) {
      errors.email = 'Required';
    } else if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i.test(values.email)) {
      errors.email = 'Invalid email address';
    }

    return errors;
  };

  const handleSubmit = useCallback(async (values) => {
    navigate(`/return?id=${encodeURIComponent(values.name)}&email=${encodeURIComponent(values.email)}`);
  }, [navigate]);

  return (
    <div className={styles.wrapper}>
      <h2 className={styles.header}>Find your trial order</h2>
      {queryParams.get('err')
        && <div className={styles.error}>Order not found</div>}
      <Formik
        initialValues={{
          name: '',
          email: '',
        }}
        validate={validate}
        onSubmit={handleSubmit}
      >
        {() => (
          <Form className={styles.formWrapper}>
            <Field name="name">
              {({ field, meta }) => (
                <div className={styles.inputGroup}>
                  <label htmlFor="name">
                    Order Number
                  </label>

                  <div>
                    <input id="name" type="text" name={field.name} value={field.value} onChange={field.onChange} className={styles.input} />
                    {meta.touched && meta.error && (
                      <div className={styles.error}>{meta.error}</div>
                    )}
                  </div>
                </div>
              )}
            </Field>
            <Field name="email">
              {({ field, meta }) => (
                <div className={styles.inputGroup}>
                  <label htmlFor="email">
                    E-mail Address
                  </label>

                  <div>
                    <input id="email" type="text" name={field.name} value={field.value} onChange={field.onChange} className={styles.input} />
                    {meta.touched && meta.error && (
                      <div className={styles.error}>{meta.error}</div>
                    )}
                  </div>
                </div>
              )}
            </Field>
            <button className={styles.button} type="submit">Find Order</button>
          </Form>
        )}
      </Formik>
    </div>
  );
}
