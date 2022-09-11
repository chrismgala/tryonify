import React from 'react';
import styles from './actions.module.css';

export default function Actions({ children }) {
  return (
    <div className={styles.actions}>
      {children}
    </div>
  )
}