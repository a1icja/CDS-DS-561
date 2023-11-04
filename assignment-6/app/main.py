import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier


def load_data() -> pd.DataFrame:
    return pd.read_csv(
        "links.csv",
        names=[
            "req_id",
            "req_ts",
            "file_req",
            "is_banned",
            "req_country",
            "req_ip",
            "req_gender",
            "req_age",
            "req_income",
        ],
    )


def remove_dupes(df: pd.DataFrame) -> pd.DataFrame:
    return df.drop_duplicates(subset=df.drop("req_id", axis=1).columns, keep="first")


def model_1(df: pd.DataFrame):
    m1_x = df["req_ip"]
    m1_y = df["req_country"]

    m1_x = pd.Categorical(m1_x).codes.reshape(-1, 1)
    m1_y = pd.Categorical(m1_y).codes.reshape(-1, 1)

    m1_x_train, m1_x_test, m1_y_train, m1_y_test = train_test_split(
        m1_x, m1_y, test_size=0.2
    )

    ip_to_country_clf = DecisionTreeClassifier()
    ip_to_country_clf.fit(m1_x_train, m1_y_train)

    test_acc = ip_to_country_clf.score(m1_x_test, m1_y_test)
    print(f"[Model 1] Testing Accuracy: {test_acc}")


def model_2(df: pd.DataFrame):
    m2_x = df.drop("req_income", axis=1)
    m2_y = df["req_income"]

    m2_x = m2_x.apply(lambda col: pd.Categorical(col).codes)

    m2_x_train, m2_x_test, m2_y_train, m2_y_test = train_test_split(
        m2_x, m2_y, test_size=0.2
    )

    income_clf = DecisionTreeClassifier()
    income_clf.fit(m2_x_train, m2_y_train)

    test_acc = income_clf.score(m2_x_test, m2_y_test)
    print(f"[Model 2] Testing Accuracy: {test_acc}")


if __name__ == "__main__":
    df = load_data()
    df = remove_dupes(df)
    model_1(df)
    model_2(df)
